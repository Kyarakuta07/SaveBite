<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('merchant_violations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('merchant_id')->constrained('merchants')->cascadeOnDelete();
            $table->foreignId('dispute_id')->constrained('disputes')->comment('Sumber komplain');
            $table->tinyInteger('violation_number')->comment('Pelanggaran ke-1, 2, 3, 4');
            $table->enum('action_taken', ['warning', 'suspended_3d', 'suspended_7d', 'banned']);
            $table->text('notes')->nullable();
            $table->foreignId('actioned_by')->nullable()->constrained('admins')->nullOnDelete();
            $table->timestamp('actioned_at')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('merchant_violations');
    }
};
