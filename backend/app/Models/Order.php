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

    // ─── Business Logic ─────────────────────────────

    /**
     * Generate kode order: SB-YYYYMMDD-XXXX
     */
    public static function generateOrderCode(): string
    {
        $date = now()->format('Ymd');
        $lastOrder = static::where('order_code', 'like', "SB-{$date}-%")
                           ->orderBy('order_code', 'desc')
                           ->first();

        if ($lastOrder) {
            $lastNumber = (int) substr($lastOrder->order_code, -4);
            $nextNumber = $lastNumber + 1;
        } else {
            $nextNumber = 1;
        }

        return sprintf('SB-%s-%04d', $date, $nextNumber);
    }
}
