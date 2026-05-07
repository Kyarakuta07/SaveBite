<?php

namespace App\Console\Commands;

use App\Models\FoodItem;
use App\Models\Order;
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

        $count = 0;

        foreach ($expiredOrders as $order) {
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

                $order->update([
                    'order_status'   => 'cancelled',
                    'payment_status' => 'failed',
                ]);
            });

            $count++;
        }

        $this->info("Cancelled {$count} expired pending orders.");
        Log::info("CancelExpiredOrders: cancelled {$count} orders.");

        return self::SUCCESS;
    }
}
