<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeliveryController extends Controller
{
    /**
     * GET /api/v1/orders/{id}/delivery
     * Status delivery + info driver + live tracking URL.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $order    = $request->user()->orders()->with('delivery')->findOrFail($id);
        $delivery = $order->delivery;

        if (! $delivery) {
            return response()->json([
                'success' => false,
                'message' => 'Data pengiriman belum tersedia.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data'    => [
                'provider'          => $delivery->provider,
                'tracking_id'       => $delivery->tracking_id,
                'status'            => $delivery->status,
                'driver'            => [
                    'name'    => $delivery->driver_name,
                    'phone'   => $delivery->driver_phone,
                    'vehicle' => $delivery->driver_vehicle,
                ],
                'live_tracking_url' => $delivery->live_tracking_url,
                'estimated_arrival' => $delivery->estimated_arrival,
                'actual_arrival'    => $delivery->actual_arrival,
            ],
        ]);
    }

    /**
     * POST /api/v1/orders/{id}/self-pickup
     * User pilih self-pickup (jika kurir gagal).
     */
    public function selfPickup(Request $request, int $id): JsonResponse
    {
        $order    = $request->user()->orders()->with(['delivery', 'merchant'])->findOrFail($id);
        $delivery = $order->delivery;

        if (! $delivery || $delivery->status !== 'failed') {
            return response()->json([
                'success' => false,
                'message' => 'Opsi self-pickup hanya tersedia jika kurir gagal menemukan driver.',
            ], 422);
        }

        // Anonymous merchants cannot do self-pickup
        if ($order->merchant->is_anonymous) {
            return response()->json([
                'success' => false,
                'message' => 'Toko ini tidak mendukung self-pickup.',
            ], 422);
        }

        // Mark delivery status accordingly (no delivery needed, order goes direct)
        $delivery->update(['status' => 'delivered', 'actual_arrival' => now()]);
        $order->update(['order_status' => 'delivered']);

        return response()->json([
            'success' => true,
            'message' => 'Self-pickup dipilih. Silakan ambil pesanan di alamat toko.',
            'data'    => [
                'pickup_address' => $order->merchant->address,
                'merchant_phone' => $order->merchant->phone,
            ],
        ]);
    }
}
