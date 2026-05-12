<?php

namespace App\Console\Commands;

use App\Models\AppSetting;
use App\Models\Merchant;
use App\Models\Order;
use App\Models\WalletTransaction;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class AutoCompleteOrders extends Command
{
    protected $signature = 'orders:auto-complete';

    protected $description = 'Auto-complete orders that have been in "delivered" status longer than the configured timeout (default: 1 hour)';

    public function handle(): int
    {
        $hours = (int) AppSetting::getValue('order_auto_complete_hours', 1);

        $orders = Order::where('order_status', 'delivered')
            ->where('updated_at', '<', now()->subHours($hours))
            ->with('items')
            ->get();

        $count = 0;

        foreach ($orders as $order) {
            try {
                DB::transaction(function () use ($order): void {
                    $order->update([
                        'order_status' => 'completed',
                        'completed_at' => now(),
                    ]);

                    // Transfer funds to merchant (subtotal - commission)
                    $merchant = Merchant::where('id', $order->merchant_id)->lockForUpdate()->first();
                    $merchantAmount = $order->subtotal - $order->commission_fee;

                    WalletTransaction::create([
                        'owner_type'     => 'merchant',
                        'owner_id'       => $merchant->id,
                        'type'           => 'income',
                        'amount'         => $merchantAmount,
                        'balance_before' => $merchant->wallet_balance,
                        'balance_after'  => $merchant->wallet_balance + $merchantAmount,
                        'reference_type' => 'order',
                        'reference_id'   => $order->id,
                        'description'    => "Pendapatan order {$order->order_code} (auto-complete)",
                    ]);
                    $merchant->increment('wallet_balance', $merchantAmount);

                    // Record platform commission
                    WalletTransaction::create([
                        'owner_type'     => 'platform',
                        'owner_id'       => 0,
                        'type'           => 'commission',
                        'amount'         => $order->commission_fee,
                        'balance_before' => 0,
                        'balance_after'  => 0,
                        'reference_type' => 'order',
                        'reference_id'   => $order->id,
                        'description'    => "Komisi order {$order->order_code} (auto-complete)",
                    ]);

                    // Update gamification stats
                    $user = $order->user;
                    $user->increment('total_saved', $order->savings_amount);
                    $user->increment('total_rescued', $order->items->sum('quantity'));
                });

                $count++;
            } catch (\Exception $e) {
                Log::error("AutoCompleteOrders: failed for order #{$order->id}: {$e->getMessage()}");
            }
        }

        $this->info("Auto-completed {$count} orders (threshold: {$hours}h).");
        Log::info("AutoCompleteOrders: completed {$count} orders.");

        return self::SUCCESS;
    }
}
