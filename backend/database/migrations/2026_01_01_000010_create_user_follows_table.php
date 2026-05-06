<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_follows', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('merchant_id')->constrained('merchants')->cascadeOnDelete();
            $table->boolean('notify_new_item')->default(true)->comment('Push notif saat ada item baru');
            $table->timestamp('created_at')->useCurrent();

            $table->unique(['user_id', 'merchant_id'], 'unique_follow');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_follows');
    }
};
