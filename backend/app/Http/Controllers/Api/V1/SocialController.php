<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Merchant;
use App\Models\Notification;
use App\Models\UserFollow;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SocialController extends Controller
{
    /**
     * POST /api/v1/merchants/{id}/follow
     * Follow toko.
     */
    public function follow(Request $request, int $merchantId): JsonResponse
    {
        Merchant::findOrFail($merchantId);

        $user    = $request->user();
        $already = UserFollow::where('user_id', $user->id)
            ->where('merchant_id', $merchantId)
            ->exists();

        if ($already) {
            return response()->json([
                'success' => false,
                'message' => 'Anda sudah mengikuti toko ini.',
            ], 422);
        }

        UserFollow::create([
            'user_id'     => $user->id,
            'merchant_id' => $merchantId,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Berhasil mengikuti toko',
        ]);
    }

    /**
     * DELETE /api/v1/merchants/{id}/follow
     * Unfollow toko.
     */
    public function unfollow(Request $request, int $merchantId): JsonResponse
    {
        $deleted = UserFollow::where('user_id', $request->user()->id)
            ->where('merchant_id', $merchantId)
            ->delete();

        if (! $deleted) {
            return response()->json([
                'success' => false,
                'message' => 'Anda belum mengikuti toko ini.',
            ], 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Berhasil berhenti mengikuti toko',
        ]);
    }

    /**
     * GET /api/v1/me/follows
     * Daftar toko yang di-follow.
     */
    public function myFollows(Request $request): JsonResponse
    {
        $follows = $request->user()
            ->follows()
            ->with('merchant:id,display_name,is_anonymous,category,average_rating,logo')
            ->paginate(20);

        $data = $follows->map(function ($follow) {
            $merchant    = $follow->merchant;
            $displayName = $merchant->is_anonymous
                ? ($merchant->display_name ?? 'Toko Anonim #' . $merchant->id)
                : ($merchant->display_name ?? $merchant->name);

            return [
                'merchant_id'    => $merchant->id,
                'display_name'   => $displayName,
                'is_anonymous'   => $merchant->is_anonymous,
                'category'       => $merchant->category,
                'average_rating' => $merchant->average_rating,
                'logo'           => $merchant->logo ? asset('storage/' . $merchant->logo) : null,
            ];
        });

        return response()->json([
            'success' => true,
            'data'    => $data,
            'meta'    => [
                'current_page' => $follows->currentPage(),
                'last_page'    => $follows->lastPage(),
                'per_page'     => $follows->perPage(),
                'total'        => $follows->total(),
            ],
        ]);
    }

    /**
     * GET /api/v1/me/notifications
     * Riwayat notifikasi user.
     */
    public function notifications(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        $notifications = Notification::where('user_id', $userId)
            ->latest('sent_at')
            ->paginate(30);

        return response()->json([
            'success' => true,
            'data'    => $notifications->items(),
            'meta'    => [
                'current_page'  => $notifications->currentPage(),
                'last_page'     => $notifications->lastPage(),
                'per_page'      => $notifications->perPage(),
                'total'         => $notifications->total(),
                'unread_count'  => Notification::where('user_id', $userId)
                    ->where('is_read', false)
                    ->count(),
            ],
        ]);
    }

    /**
     * POST /api/v1/me/notifications/read-all
     * Tandai semua notifikasi sudah dibaca.
     */
    public function readAllNotifications(Request $request): JsonResponse
    {
        Notification::where('user_id', $request->user()->id)
            ->where('is_read', false)
            ->update(['is_read' => true]);

        return response()->json([
            'success' => true,
            'message' => 'Semua notifikasi ditandai sudah dibaca',
        ]);
    }
}

