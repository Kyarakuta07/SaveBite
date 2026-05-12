<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreDisputeRequest;
use App\Models\AppSetting;
use App\Models\Dispute;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DisputeController extends Controller
{
    /**
     * POST /api/v1/orders/{id}/dispute
     * Ajukan komplain (max 60 menit setelah delivered).
     */
    public function store(StoreDisputeRequest $request, int $orderId): JsonResponse
    {
        $order = $request->user()->orders()->with(['dispute', 'delivery'])->findOrFail($orderId);

        // Must be delivered status
        if (! in_array($order->order_status, ['delivered', 'completed'])) {
            return response()->json([
                'success' => false,
                'message' => 'Komplain hanya bisa diajukan setelah order terkirim.',
            ], 422);
        }

        // Check if already disputed
        if ($order->dispute) {
            return response()->json([
                'success' => false,
                'message' => 'Anda sudah mengajukan komplain untuk order ini.',
            ], 422);
        }

        // Check dispute window (from app_settings)
        $windowMins = (int) AppSetting::getValue('dispute_window_mins', 60);

        $deliveredAt = $order->delivery?->actual_arrival ?? $order->updated_at;
        if (now()->diffInMinutes($deliveredAt) > $windowMins) {
            return response()->json([
                'success' => false,
                'message' => "Batas waktu pengajuan komplain ({$windowMins} menit) telah terlewat.",
            ], 422);
        }

        $validated = $request->validated();

        $photoPath = $request->file('photo_proof')->store('disputes/photos', 'public');
        $videoPath = $request->file('video_proof')->store('disputes/videos', 'public');

        $dispute = Dispute::create([
            'order_id'     => $order->id,
            'user_id'      => $request->user()->id,
            'merchant_id'  => $order->merchant_id,
            'reason'       => $validated['reason'],
            'photo_proof'  => $photoPath,
            'video_proof'  => $videoPath,
            'submitted_at' => now(),
            'status'       => 'pending',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Komplain berhasil diajukan. Tim kami akan meninjau dalam 1x24 jam.',
            'data'    => [
                'dispute_id' => $dispute->id,
                'status'     => $dispute->status,
            ],
        ], 201);
    }

    /**
     * GET /api/v1/disputes/{id}
     * Lihat status komplain.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $dispute = Dispute::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        return response()->json([
            'success' => true,
            'data'    => [
                'id'           => $dispute->id,
                'status'       => $dispute->status,
                'reason'       => $dispute->reason,
                'admin_notes'  => $dispute->admin_notes,
                'refund_amount'=> $dispute->refund_amount,
                'created_at'   => $dispute->created_at,
                'updated_at'   => $dispute->updated_at,
            ],
        ]);
    }
}
