<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class WalletTransaction extends Model
{
    use HasFactory;

    public $timestamps = false;

    protected $fillable = [
        'owner_type',
        'owner_id',
        'type',
        'amount',
        'balance_before',
        'balance_after',
        'reference_type',
        'reference_id',
        'description',
    ];

    protected function casts(): array
    {
        return [
            'amount'         => 'decimal:2',
            'balance_before' => 'decimal:2',
            'balance_after'  => 'decimal:2',
            'created_at'     => 'datetime',
        ];
    }

    // ─── Relationships ──────────────────────────────

    /**
     * Polymorphic: owner bisa User, Merchant, atau Platform.
     */
    public function owner()
    {
        return match ($this->owner_type) {
            'user'     => $this->belongsTo(User::class, 'owner_id'),
            'merchant' => $this->belongsTo(Merchant::class, 'owner_id'),
            default    => null, // 'platform' tidak punya model
        };
    }

    /**
     * Referensi ke order atau dispute terkait.
     */
    public function reference()
    {
        return match ($this->reference_type) {
            'order'   => $this->belongsTo(Order::class, 'reference_id'),
            'dispute' => $this->belongsTo(Dispute::class, 'reference_id'),
            default   => null,
        };
    }

    // ─── Scopes ─────────────────────────────────────

    public function scopeForUser($query, int $userId)
    {
        return $query->where('owner_type', 'user')->where('owner_id', $userId);
    }

    public function scopeForMerchant($query, int $merchantId)
    {
        return $query->where('owner_type', 'merchant')->where('owner_id', $merchantId);
    }

    public function scopeForPlatform($query)
    {
        return $query->where('owner_type', 'platform');
    }
}
