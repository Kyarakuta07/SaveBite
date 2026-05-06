<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('wallet_transactions', function (Blueprint $table) {
            $table->id();
            $table->enum('owner_type', ['user', 'merchant', 'platform'])->comment("'platform' = kas SaveBite");
            $table->unsignedBigInteger('owner_id');
            $table->enum('type', ['topup', 'payment', 'refund', 'withdrawal', 'commission', 'income']);
            $table->decimal('amount', 12, 2);
            $table->decimal('balance_before', 12, 2);
            $table->decimal('balance_after', 12, 2);
            $table->enum('reference_type', ['order', 'dispute', 'topup', 'withdrawal'])->nullable();
            $table->unsignedBigInteger('reference_id')->nullable()->comment('ID order atau dispute terkait');
            $table->string('description');
            $table->timestamp('created_at')->useCurrent();

            $table->index(['owner_type', 'owner_id'], 'idx_owner');
            $table->index(['reference_type', 'reference_id'], 'idx_reference');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('wallet_transactions');
    }
};
