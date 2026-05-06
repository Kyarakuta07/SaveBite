<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Delivery extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'provider',
        'tracking_id',
        'driver_name',
        'driver_phone',
        'driver_vehicle',
        'live_tracking_url',
        'status',
        'estimated_arrival',
        'actual_arrival',
        'api_response',
    ];

    protected function casts(): array
    {
        return [
            'estimated_arrival' => 'datetime',
            'actual_arrival'    => 'datetime',
            'api_response'      => 'array',
        ];
    }

    // ─── Relationships ──────────────────────────────

    public function order()
    {
        return $this->belongsTo(Order::class);
    }
}
