<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Review extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id', 'user_id', 'merchant_id', 'rating', 'comment',
        'is_anonymous', 'merchant_reply', 'replied_at', 'is_flagged', 'flag_reason',
    ];

    protected function casts(): array
    {
        return [
            'rating'       => 'integer',
            'is_anonymous' => 'boolean',
            'replied_at'   => 'datetime',
            'is_flagged'   => 'boolean',
        ];
    }

    public function order()    { return $this->belongsTo(Order::class); }
    public function user()     { return $this->belongsTo(User::class); }
    public function merchant() { return $this->belongsTo(Merchant::class); }

    /**
     * Auto-update merchant average_rating when reviews change.
     */
    protected static function booted(): void
    {
        $recalculate = function (Review $review): void {
            $merchant = $review->merchant;
            if ($merchant) {
                $merchant->update([
                    'average_rating' => $merchant->reviews()->avg('rating') ?? 0,
                    'total_reviews'  => $merchant->reviews()->count(),
                ]);
            }
        };

        static::created($recalculate);
        static::updated($recalculate);
        static::deleted($recalculate);
    }
}
