<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MerchantViolation extends Model
{
    use HasFactory;

    public $timestamps = false;

    protected $fillable = [
        'merchant_id',
        'dispute_id',
        'violation_number',
        'action_taken',
        'notes',
        'actioned_by',
        'actioned_at',
    ];

    protected function casts(): array
    {
        return [
            'violation_number' => 'integer',
            'actioned_at'      => 'datetime',
        ];
    }

    // ─── Relationships ──────────────────────────────

    public function merchant()
    {
        return $this->belongsTo(Merchant::class);
    }

    public function dispute()
    {
        return $this->belongsTo(Dispute::class);
    }

    public function actionedBy()
    {
        return $this->belongsTo(Admin::class, 'actioned_by');
    }
}
