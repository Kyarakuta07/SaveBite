<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('deliveries', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->unique()->constrained('orders')->cascadeOnDelete();
            $table->enum('provider', ['grab', 'lalamove', 'borzo']);
            $table->string('tracking_id', 100)->nullable()->comment('ID tracking dari API pihak ketiga');
            $table->string('driver_name', 100)->nullable();
            $table->string('driver_phone', 20)->nullable();
            $table->string('driver_vehicle', 50)->nullable();
            $table->string('live_tracking_url')->nullable();
            $table->enum('status', ['searching', 'driver_found', 'picked_up', 'on_the_way', 'delivered', 'failed'])->default('searching');
            $table->timestamp('estimated_arrival')->nullable();
            $table->timestamp('actual_arrival')->nullable();
            $table->json('api_response')->nullable()->comment('Raw response dari API kurir');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('deliveries');
    }
};
