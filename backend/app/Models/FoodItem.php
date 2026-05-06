<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FoodItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'merchant_id',
        'name',
        'description',
        'image',
        'original_price',
        'rescue_price',
        'discount_pct',
        'quantity',
        'reason',
        'produced_at',
        'expires_at',
        'status',
        'pickup_only',
    ];

    protected function casts(): array
    {
        return [
            'original_price' => 'decimal:2',
            'rescue_price'   => 'decimal:2',
            'discount_pct'   => 'integer',
            'quantity'        => 'integer',
            'quantity_sold'   => 'integer',
            'pickup_only'     => 'boolean',
            'produced_at'     => 'datetime',
            'expires_at'      => 'datetime',
        ];
    }

    // ─── Relationships ──────────────────────────────

    public function merchant()
    {
        return $this->belongsTo(Merchant::class);
    }

    public function orderItems()
    {
        return $this->hasMany(OrderItem::class);
    }

    // ─── Mutators ───────────────────────────────────

    /**
     * Hitung discount_pct otomatis saat set rescue_price.
     */
    protected static function booted(): void
    {
        static::saving(function (FoodItem $item) {
            if ($item->original_price > 0 && $item->rescue_price > 0) {
                $item->discount_pct = (int) round(
                    ($item->original_price - $item->rescue_price) / $item->original_price * 100
                );
            }
        });
    }

    // ─── Scopes ─────────────────────────────────────

    public function scopeAvailable($query)
    {
        return $query->where('status', 'available')
                     ->where('quantity', '>', 0);
    }

    public function scopeByMerchant($query, int $merchantId)
    {
        return $query->where('merchant_id', $merchantId);
    }
}
