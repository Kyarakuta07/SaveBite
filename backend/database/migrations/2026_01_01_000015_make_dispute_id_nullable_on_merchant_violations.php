<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('merchant_violations', function (Blueprint $table) {
            // Allow nullable dispute_id for manual admin suspensions
            $table->foreignId('dispute_id')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('merchant_violations', function (Blueprint $table) {
            $table->foreignId('dispute_id')->nullable(false)->change();
        });
    }
};
