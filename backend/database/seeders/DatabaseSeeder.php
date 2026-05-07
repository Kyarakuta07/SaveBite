<?php

namespace Database\Seeders;

use App\Models\Admin;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // ─── Default Super Admin ─────────────────────────────────────────
        Admin::firstOrCreate(
            ['email' => 'admin@savebite.id'],
            [
                'name'     => 'SaveBite Admin',
                'password' => Hash::make('savebite2026!'),
                'role'     => 'super_admin',
                'is_active'=> true,
            ]
        );

        Admin::firstOrCreate(
            ['email' => 'finance@savebite.id'],
            [
                'name'     => 'Finance Admin',
                'password' => Hash::make('savebite2026!'),
                'role'     => 'finance',
                'is_active'=> true,
            ]
        );

        $this->command->info('✅ Default admin accounts created.');
        $this->command->info('   📧 admin@savebite.id  | password: savebite2026!');
        $this->command->info('   📧 finance@savebite.id | password: savebite2026!');
        $this->command->info('   ⚠️  Ganti password sebelum deploy ke production!');
    }
}
