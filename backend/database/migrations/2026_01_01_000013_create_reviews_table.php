<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('reviews', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->unique()->constrained('orders')->comment('1 order = max 1 ulasan');
            $table->foreignId('user_id')->constrained('users');
            $table->foreignId('merchant_id')->constrained('merchants');
            $table->unsignedTinyInteger('rating')->comment('Skala 1-5 bintang');
            $table->text('comment')->nullable();
            $table->boolean('is_anonymous')->default(false);
            $table->text('merchant_reply')->nullable();
            $table->timestamp('replied_at')->nullable();
            $table->boolean('is_flagged')->default(false)->comment('Ditandai admin untuk ditindak');
            $table->text('flag_reason')->nullable();
            $table->timestamps();

            $table->index(['merchant_id', 'rating'], 'idx_merchant_rating');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reviews');
    }
};
