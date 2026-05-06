<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('order_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained('orders')->cascadeOnDelete();
            $table->foreignId('food_item_id')->constrained('food_items');
            $table->string('food_name', 200)->comment('Snapshot nama saat order');
            $table->decimal('original_price', 10, 2)->comment('Snapshot harga normal saat order');
            $table->decimal('rescue_price', 10, 2)->comment('Snapshot harga rescue saat order');
            $table->unsignedSmallInteger('quantity')->default(1);
            $table->decimal('line_total', 12, 2)->comment('rescue_price * quantity');
            $table->timestamp('created_at')->useCurrent();

            $table->index('order_id', 'idx_order_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_items');
    }
};
