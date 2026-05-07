<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Review;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReviewController extends Controller
{
    /**
     * POST /api/v1/orders/{id}/review
     * Buat review untuk order yang completed.
     */
    public function store(Request $request, int $orderId): JsonResponse
    {
        $order = $request->user()->orders()->findOrFail($orderId);

        if ($order->order_status !== 'completed') {
            return response()->json([
                'success' => false,
                'message' => 'Review hanya bisa diberikan setelah order selesai.',
            ], 422);
        }

        if ($order->review) {
            return response()->json([
                'success' => false,
                'message' => 'Anda sudah memberikan review untuk order ini.',
            ], 422);
        }

        $validated = $request->validate([
            'rating'       => ['required', 'integer', 'min:1', 'max:5'],
            'comment'      => ['nullable', 'string', 'max:500'],
            'is_anonymous' => ['sometimes', 'boolean'],
        ]);

        $review = Review::create([
            'order_id'     => $order->id,
            'user_id'      => $request->user()->id,
            'merchant_id'  => $order->merchant_id,
            'rating'       => $validated['rating'],
            'comment'      => $validated['comment'] ?? null,
            'is_anonymous' => $validated['is_anonymous'] ?? false,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Review berhasil dikirim. Terima kasih!',
            'data'    => $review,
        ], 201);
    }

    /**
     * GET /api/v1/merchants/{id}/reviews
     * Lihat semua review sebuah toko.
     */
    public function merchantReviews(Request $request, int $merchantId): JsonResponse
    {
        $reviews = Review::where('merchant_id', $merchantId)
            ->with(['user:id,name,avatar'])
            ->latest()
            ->paginate(20);

        $data = $reviews->map(function ($review) {
            $reviewerName = $review->is_anonymous ? 'Pengguna Anonim' : $review->user->name;
            $reviewerAvatar = $review->is_anonymous ? null : $review->user->avatar;

            return [
                'id'            => $review->id,
                'reviewer_name' => $reviewerName,
                'reviewer_avatar' => $reviewerAvatar,
                'rating'        => $review->rating,
                'comment'       => $review->comment,
                'merchant_reply' => $review->merchant_reply,
                'created_at'    => $review->created_at,
            ];
        });

        return response()->json([
            'success' => true,
            'data'    => $data,
            'meta'    => [
                'current_page' => $reviews->currentPage(),
                'last_page'    => $reviews->lastPage(),
                'per_page'     => $reviews->perPage(),
                'total'        => $reviews->total(),
            ],
        ]);
    }
}
