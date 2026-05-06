<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('food_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('merchant_id')->constrained('merchants')->cascadeOnDelete();
            $table->string('name', 200);
            $table->text('description')->nullable();
            $table->string('image')->nullable();
            $table->decimal('original_price', 10, 2)->comment('Harga normal');
            $table->decimal('rescue_price', 10, 2)->comment('Harga SaveBite (diskon)');
            $table->unsignedTinyInteger('discount_pct')->comment('Persentase diskon (%)');
            $table->unsignedSmallInteger('quantity')->default(1)->comment('Stok tersedia');
            $table->unsignedSmallInteger('quantity_sold')->default(0);
            $table->string('reason')->comment('Toko mau tutup, Stok berlebih, dll');
            $table->dateTime('produced_at')->nullable()->comment('Waktu produksi');
            $table->dateTime('expires_at')->nullable()->comment('Waktu kedaluwarsa');
            $table->enum('status', ['available', 'sold_out', 'expired', 'cancelled'])->default('available');
            $table->boolean('pickup_only')->default(false)->comment('1 = Hanya self-pickup');
            $table->timestamps();

            $table->index('status', 'idx_status');
            $table->index(['merchant_id', 'status'], 'idx_merchant_status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('food_items');
    }
};
