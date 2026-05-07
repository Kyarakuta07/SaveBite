<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserAddress extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'label',
        'recipient_name',
        'phone',
        'address',
        'detail',
        'latitude',
        'longitude',
        'is_default',
    ];

    protected function casts(): array
    {
        return [
            'latitude'   => 'decimal:8',
            'longitude'  => 'decimal:8',
            'is_default' => 'boolean',
        ];
    }

    // ─── Relationships ──────────────────────────────

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
