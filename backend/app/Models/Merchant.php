<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class Merchant extends Authenticatable
{
    use HasApiTokens, HasFactory;

    protected $fillable = [
        'name',
        'display_name',
        'is_anonymous',
        'category',
        'email',
        'phone',
        'password',
        'logo',
        'address',
        'latitude',
        'longitude',
        'operational_hours',
        'wallet_balance',
        'average_rating',
        'total_reviews',
        'status',
        'suspension_until',
        'violation_count',
        'fcm_token',
        'is_verified',
    ];

    protected $hidden = [
        'password',
    ];

    protected function casts(): array
    {
        return [
            'is_anonymous'      => 'boolean',
            'operational_hours' => 'array',
            'wallet_balance'    => 'decimal:2',
            'average_rating'    => 'decimal:2',
            'total_reviews'     => 'integer',
            'latitude'          => 'decimal:8',
            'longitude'         => 'decimal:8',
            'suspension_until'  => 'date',
            'violation_count'   => 'integer',
            'is_verified'       => 'boolean',
            'password'          => 'hashed',
        ];
    }

    // ─── Relationships ──────────────────────────────

    public function foodItems()
    {
        return $this->hasMany(FoodItem::class);
    }

    public function orders()
    {
        return $this->hasMany(Order::class);
    }

    public function reviews()
    {
        return $this->hasMany(Review::class);
    }

    public function violations()
    {
        return $this->hasMany(MerchantViolation::class);
    }

    public function followers()
    {
        return $this->hasMany(UserFollow::class);
    }

    public function followerUsers()
    {
        return $this->belongsToMany(User::class, 'user_follows')
                    ->withPivot('notify_new_item')
                    ->withTimestamps();
    }

    public function walletTransactions()
    {
        return $this->hasMany(WalletTransaction::class, 'owner_id')
                    ->where('owner_type', 'merchant');
    }

    public function disputes()
    {
        return $this->hasMany(Dispute::class);
    }

    // ─── Accessors ──────────────────────────────────

    /**
     * Nama publik yang tampil ke user.
     * Jika anonymous dan belum punya display_name, generate nama samaran.
     */
    public function getPublicNameAttribute(): string
    {
        if ($this->is_anonymous) {
            return $this->display_name ?? 'Mitra SaveBite #' . $this->id;
        }

        return $this->display_name ?? $this->name;
    }
}
