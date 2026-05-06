<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name', 100);
            $table->string('email', 150)->unique();
            $table->string('phone', 20)->unique();
            $table->string('password');
            $table->string('avatar')->nullable();
            $table->decimal('wallet_balance', 12, 2)->default(0.00);
            $table->unsignedInteger('point_balance')->default(0);
            $table->decimal('total_saved', 12, 2)->default(0.00)->comment('Total uang dihemat (Rp)');
            $table->unsignedInteger('total_rescued')->default(0)->comment('Total porsi diselamatkan');
            $table->string('fcm_token')->nullable()->comment('Token untuk Push Notification');
            $table->boolean('is_active')->default(true);
            $table->timestamp('email_verified_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};
