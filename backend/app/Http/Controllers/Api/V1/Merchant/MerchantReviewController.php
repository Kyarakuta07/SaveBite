<?php

namespace App\Http\Controllers\Api\V1\Merchant;

use App\Http\Controllers\Controller;
use App\Models\Review;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MerchantReviewController extends Controller
{
    /**
     * POST /api/v1/merchant/reviews/{id}/reply
     * Mitra balas review.
     */
    public function reply(Request $request, int $id): JsonResponse
    {
        $review = Review::where('id', $id)
            ->where('merchant_id', $request->user()->id)
            ->firstOrFail();

        if ($review->merchant_reply) {
            return response()->json([
                'success' => false,
                'message' => 'Anda sudah membalas review ini.',
            ], 422);
        }

        $validated = $request->validate([
            'reply' => ['required', 'string', 'max:500'],
        ]);

        $review->update(['merchant_reply' => $validated['reply'], 'replied_at' => now()]);

        return response()->json([
            'success' => true,
            'message' => 'Balasan berhasil dikirim',
            'data'    => $review->fresh(),
        ]);
    }
}
