<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'phone',
        'password',
        'avatar',
        'wallet_balance',
        'point_balance',
        'total_saved',
        'total_rescued',
        'fcm_token',
        'is_active',
    ];

    protected $hidden = [
        'password',
    ];

    protected function casts(): array
    {
        return [
            'wallet_balance'    => 'decimal:2',
            'total_saved'       => 'decimal:2',
            'point_balance'     => 'integer',
            'total_rescued'     => 'integer',
            'is_active'         => 'boolean',
            'email_verified_at' => 'datetime',
            'password'          => 'hashed',
        ];
    }

    // ─── Relationships ──────────────────────────────

    public function orders()
    {
        return $this->hasMany(Order::class);
    }

    public function reviews()
    {
        return $this->hasMany(Review::class);
    }

    public function follows()
    {
        return $this->hasMany(UserFollow::class);
    }

    public function followedMerchants()
    {
        return $this->belongsToMany(Merchant::class, 'user_follows')
                    ->withPivot('notify_new_item')
                    ->withTimestamps();
    }

    public function notifications()
    {
        return $this->hasMany(Notification::class);
    }

    public function walletTransactions()
    {
        return $this->hasMany(WalletTransaction::class, 'owner_id')
                    ->where('owner_type', 'user');
    }

    public function disputes()
    {
        return $this->hasMany(Dispute::class);
    }

    public function addresses()
    {
        return $this->hasMany(UserAddress::class)->orderByDesc('is_default');
    }

    public function defaultAddress()
    {
        return $this->hasOne(UserAddress::class)->where('is_default', true);
    }

    // ─── Computed Attributes ────────────────────────

    /**
     * Badge tier berdasarkan total_saved (Rp).
     * Matches UI: Mahasiswa Hemat, Pemburu Diskon, Eco Warrior, SaveBite Legend
     */
    public function getTierAttribute(): array
    {
        $saved = (float) $this->total_saved;

        return match(true) {
            $saved >= 5_000_000 => ['name' => 'SaveBite Legend',  'icon' => '🏆', 'min_saved' => 5_000_000],
            $saved >= 1_000_000 => ['name' => 'Eco Warrior',      'icon' => '🌿', 'min_saved' => 1_000_000],
            $saved >= 200_000  => ['name' => 'Pemburu Diskon',   'icon' => '🎯', 'min_saved' => 200_000],
            default            => ['name' => 'Mahasiswa Hemat',  'icon' => '🎓', 'min_saved' => 0],
        };
    }
}
