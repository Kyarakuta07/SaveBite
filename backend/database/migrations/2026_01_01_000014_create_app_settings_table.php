<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('app_settings', function (Blueprint $table) {
            $table->increments('id');
            $table->string('setting_key', 100)->unique()->comment("'key' is reserved in MySQL");
            $table->text('value');
            $table->string('description')->nullable();
            $table->foreignId('updated_by')->nullable()->constrained('admins')->nullOnDelete();
            $table->timestamp('updated_at')->useCurrent()->useCurrentOnUpdate();
        });

        // Seed data default
        DB::table('app_settings')->insert([
            [
                'setting_key' => 'commission_rate',
                'value'       => '5',
                'description' => 'Persentase komisi SaveBite dari setiap transaksi (%)',
                'updated_by'  => null,
            ],
            [
                'setting_key' => 'dispute_window_mins',
                'value'       => '60',
                'description' => 'Batas waktu pengajuan komplain setelah order selesai (menit)',
                'updated_by'  => null,
            ],
            [
                'setting_key' => 'max_violation',
                'value'       => '4',
                'description' => 'Jumlah pelanggaran sebelum mitra di-banned permanen',
                'updated_by'  => null,
            ],
            [
                'setting_key' => 'order_auto_complete_hours',
                'value'       => '1',
                'description' => 'Jam setelah delivered sebelum order auto-complete',
                'updated_by'  => null,
            ],
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('app_settings');
    }
};
