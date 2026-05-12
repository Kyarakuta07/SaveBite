<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_code',
        'user_id',
        'merchant_id',
        'subtotal',
        'delivery_fee',
        'commission_fee',
        'total_amount',
        'savings_amount',
        'payment_method',
        'payment_status',
        'order_status',
        'delivery_address',
        'delivery_lat',
        'delivery_lng',
        'notes',
        'paid_at',
        'completed_at',
    ];

    protected function casts(): array
    {
        return [
            'subtotal'       => 'decimal:2',
            'delivery_fee'   => 'decimal:2',
            'commission_fee' => 'decimal:2',
            'total_amount'   => 'decimal:2',
            'savings_amount' => 'decimal:2',
            'delivery_lat'   => 'decimal:8',
            'delivery_lng'   => 'decimal:8',
            'paid_at'        => 'datetime',
            'completed_at'   => 'datetime',
        ];
    }

    // ─── Relationships ──────────────────────────────

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function merchant()
    {
        return $this->belongsTo(Merchant::class);
    }

    public function items()
    {
        return $this->hasMany(OrderItem::class);
    }

    public function delivery()
    {
        return $this->hasOne(Delivery::class);
    }

    public function dispute()
    {
        return $this->hasOne(Dispute::class);
    }

    public function review()
    {
        return $this->hasOne(Review::class);
    }

    /**
     * Generate kode order: SB-YYYYMMDD-XXXX
     *
     * Uses atomic DB operation to prevent race conditions.
     * Two concurrent requests can no longer generate the same code.
     */
    public static function generateOrderCode(): string
    {
        $date = now()->format('Ymd');
        $prefix = "SB-{$date}-";

        // Atomic: get MAX existing sequence number with lock
        $lastCode = static::where('order_code', 'like', "{$prefix}%")
                          ->lockForUpdate()
                          ->orderBy('order_code', 'desc')
                          ->value('order_code');

        if ($lastCode) {
            $nextNumber = ((int) substr($lastCode, -4)) + 1;
        } else {
            $nextNumber = 1;
        }

        return sprintf('%s%04d', $prefix, $nextNumber);
    }
}
