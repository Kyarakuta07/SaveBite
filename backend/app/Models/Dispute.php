<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Dispute extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'user_id',
        'merchant_id',
        'reason',
        'photo_proof',
        'video_proof',
        'submitted_at',
        'status',
        'admin_notes',
        'resolved_by',
        'refund_amount',
        'resolved_at',
    ];

    protected function casts(): array
    {
        return [
            'submitted_at'  => 'datetime',
            'resolved_at'   => 'datetime',
            'refund_amount' => 'decimal:2',
        ];
    }

    // ─── Relationships ──────────────────────────────

    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function merchant()
    {
        return $this->belongsTo(Merchant::class);
    }

    public function resolver()
    {
        return $this->belongsTo(Admin::class, 'resolved_by');
    }

    public function violation()
    {
        return $this->hasOne(MerchantViolation::class);
    }
}
