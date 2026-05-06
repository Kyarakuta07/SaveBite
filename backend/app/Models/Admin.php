<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class Admin extends Authenticatable
{
    use HasApiTokens, HasFactory;

    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'is_active',
    ];

    protected $hidden = [
        'password',
    ];

    protected function casts(): array
    {
        return [
            'is_active'     => 'boolean',
            'last_login_at' => 'datetime',
            'password'      => 'hashed',
        ];
    }

    // ─── Relationships ──────────────────────────────

    public function resolvedDisputes()
    {
        return $this->hasMany(Dispute::class, 'resolved_by');
    }

    public function actionedViolations()
    {
        return $this->hasMany(MerchantViolation::class, 'actioned_by');
    }

    public function updatedSettings()
    {
        return $this->hasMany(AppSetting::class, 'updated_by');
    }
}
