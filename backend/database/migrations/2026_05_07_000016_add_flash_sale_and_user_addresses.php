<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Flash Sale fields on food_items
        Schema::table('food_items', function (Blueprint $table) {
            $table->boolean('is_flash_sale')->default(false)->after('pickup_only');
            $table->dateTime('flash_sale_ends_at')->nullable()->after('is_flash_sale')
                  ->comment('Batas waktu flash sale — NULL jika bukan flash sale');

            $table->index(['is_flash_sale', 'flash_sale_ends_at'], 'idx_flash_sale');
        });

        // 2. User addresses table
        Schema::create('user_addresses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('label', 50)->comment('Rumah, Kantor, Kos, dll');
            $table->string('recipient_name', 100);
            $table->string('phone', 20);
            $table->text('address');
            $table->string('detail', 200)->nullable()->comment('Nomor unit, lantai, patokan');
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();
            $table->boolean('is_default')->default(false);
            $table->timestamps();

            $table->index(['user_id', 'is_default'], 'idx_user_default_address');
        });
    }

    public function down(): void
    {
        Schema::table('food_items', function (Blueprint $table) {
            $table->dropIndex('idx_flash_sale');
            $table->dropColumn(['is_flash_sale', 'flash_sale_ends_at']);
        });

        Schema::dropIfExists('user_addresses');
    }
};
