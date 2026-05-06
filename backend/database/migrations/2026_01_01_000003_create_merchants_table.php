<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('merchants', function (Blueprint $table) {
            $table->id();
            $table->string('name', 150)->comment('Nama asli toko');
            $table->string('display_name', 150)->nullable()->comment('Nama publik (NULL jika anonymous)');
            $table->boolean('is_anonymous')->default(false)->comment('1 = Sembunyikan nama brand');
            $table->enum('category', ['fast_food', 'bakery', 'supermarket']);
            $table->string('email', 150)->unique();
            $table->string('phone', 20);
            $table->string('password');
            $table->string('logo')->nullable();
            $table->text('address');
            $table->decimal('latitude', 10, 8);
            $table->decimal('longitude', 11, 8);
            $table->json('operational_hours')->nullable()->comment('{"mon": "08:00-22:00", ...}');
            $table->decimal('wallet_balance', 12, 2)->default(0.00);
            $table->decimal('average_rating', 3, 2)->default(0.00)->comment('Rata-rata bintang');
            $table->unsignedInteger('total_reviews')->default(0);
            $table->enum('status', ['active', 'suspended', 'banned'])->default('active');
            $table->date('suspension_until')->nullable()->comment('Tanggal berakhirnya masa skors');
            $table->tinyInteger('violation_count')->default(0);
            $table->string('fcm_token')->nullable();
            $table->boolean('is_verified')->default(false)->comment('Verifikasi oleh admin SaveBite');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('merchants');
    }
};
