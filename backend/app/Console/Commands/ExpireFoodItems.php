<?php

namespace App\Console\Commands;

use App\Models\FoodItem;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;

class ExpireFoodItems extends Command
{
    protected $signature = 'food:expire-stale';

    protected $description = 'Mark food items past their expires_at as expired so they no longer appear in listings';

    public function handle(): int
    {
        $count = FoodItem::where('status', 'available')
            ->whereNotNull('expires_at')
            ->where('expires_at', '<', now())
            ->update(['status' => 'expired']);

        $this->info("Marked {$count} food items as expired.");
        Log::info("ExpireFoodItems: marked {$count} items as expired.");

        return self::SUCCESS;
    }
}
