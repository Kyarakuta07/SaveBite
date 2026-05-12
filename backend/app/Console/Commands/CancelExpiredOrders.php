<?php

namespace App\Console\Commands;

use App\Models\FoodItem;
use App\Models\Order;
use App\Models\User;
use App\Models\WalletTransaction;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class CancelExpiredOrders extends Command
{
    protected $signature = 'orders:cancel-expired';

    protected $description = 'Cancel pending orders that have not been paid within 30 minutes and restore their stock';

    public function handle(): int
    {
        $expiredOrders = Order::where('order_status', 'pending')
            ->where('payment_status', 'pending')
            ->where('created_at', '<', now()->subMinutes(30))
            ->with('items')
            ->get();

        // Also cancel confirmed wallet-paid orders that merchant hasn't acted on in 2 hours
        $stalledOrders = Order::where('order_status', 'confirmed')
            ->where('payment_status', 'paid')
            ->where('payment_method', 'wallet')
            ->where('updated_at', '<', now()->subHours(2))
            ->with('items')
            ->get();

        $allOrders = $expiredOrders->merge($stalledOrders);
        $count = 0;

        foreach ($allOrders as $order) {
            try {
                DB::transaction(function () use ($order): void {
                    // Restore stock for each item
                    foreach ($order->items as $item) {
                        $foodItem = FoodItem::where('id', $item->food_item_id)->first();
                        if ($foodItem) {
                            $foodItem->increment('quantity', $item->quantity);
                            // Re-activate if it was sold out due to this order
                            if ($foodItem->fresh()->status === 'sold_out') {
                                $foodItem->update(['status' => 'available']);
                            }
                        }
                    }

                    // Refund wallet if order was paid via wallet
                    if ($order->payment_method === 'wallet' && $order->payment_status === 'paid') {
                        $user = User::where('id', $order->user_id)->lockForUpdate()->first();
                        if ($user) {
                            WalletTransaction::create([
                                'owner_type'     => 'user',
                                'owner_id'       => $user->id,
                                'type'           => 'refund',
                                'amount'         => $order->total_amount,
                                'balance_before' => $user->wallet_balance,
                                'balance_after'  => $user->wallet_balance + $order->total_amount,
                                'reference_type' => 'order',
                                'reference_id'   => $order->id,
                                'description'    => "Refund otomatis order {$order->order_code} (expired)",
                            ]);
                            $user->increment('wallet_balance', $order->total_amount);
                        }
                    }

                    $order->update([
                        'order_status'   => 'cancelled',
                        'payment_status' => $order->payment_status === 'paid' ? 'refunded' : 'failed',
                    ]);
                });

                $count++;
            } catch (\Exception $e) {
                Log::error("CancelExpiredOrders: failed for order #{$order->id}: {$e->getMessage()}");
            }
        }

        $this->info("Cancelled {$count} expired/stalled orders.");
        Log::info("CancelExpiredOrders: cancelled {$count} orders.");

        return self::SUCCESS;
    }
}
