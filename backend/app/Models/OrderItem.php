<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderItem extends Model
{
    use HasFactory;

    public $timestamps = false;

    protected $fillable = [
        'order_id',
        'food_item_id',
        'food_name',
        'original_price',
        'rescue_price',
        'quantity',
        'line_total',
    ];

    protected function casts(): array
    {
        return [
            'original_price' => 'decimal:2',
            'rescue_price'   => 'decimal:2',
            'quantity'        => 'integer',
            'line_total'      => 'decimal:2',
            'created_at'      => 'datetime',
        ];
    }

    // ─── Relationships ──────────────────────────────

    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    public function foodItem()
    {
        return $this->belongsTo(FoodItem::class);
    }
}
