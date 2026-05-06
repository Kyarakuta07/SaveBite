<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->string('order_code', 20)->unique()->comment('Format: SB-YYYYMMDD-XXXX');
            $table->foreignId('user_id')->constrained('users');
            $table->foreignId('merchant_id')->constrained('merchants');
            $table->decimal('subtotal', 12, 2)->comment('Total harga semua item');
            $table->decimal('delivery_fee', 10, 2)->default(0.00);
            $table->decimal('commission_fee', 10, 2)->default(0.00)->comment('Komisi SaveBite 5%');
            $table->decimal('total_amount', 12, 2)->comment('Grand total dibayar user');
            $table->decimal('savings_amount', 12, 2)->default(0.00)->comment('Total penghematan user');
            $table->enum('payment_method', ['wallet', 'qris', 'e_wallet', 'bank_transfer']);
            $table->enum('payment_status', ['pending', 'paid', 'failed', 'refunded'])->default('pending');
            $table->enum('order_status', ['pending', 'confirmed', 'picked_up', 'delivered', 'completed', 'cancelled'])->default('pending');
            $table->text('delivery_address')->nullable();
            $table->decimal('delivery_lat', 10, 8)->nullable();
            $table->decimal('delivery_lng', 11, 8)->nullable();
            $table->text('notes')->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamps();

            $table->index('user_id', 'idx_user_id');
            $table->index('merchant_id', 'idx_merchant_id');
            $table->index('order_status', 'idx_order_status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
