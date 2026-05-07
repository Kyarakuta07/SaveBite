<?php

namespace App\Http\Controllers\Api\V1\Merchant;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MerchantOrderController extends Controller
{
    /**
     * GET /api/v1/merchant/orders
     * Daftar order masuk untuk mitra.
     */
    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'status' => ['nullable', 'in:pending,confirmed,picked_up,delivered,completed,cancelled'],
            'page'   => ['nullable', 'integer', 'min:1'],
        ]);

        $query = $request->user()
            ->orders()
            ->with(['items', 'user:id,name,phone'])
            ->latest();

        if (! empty($validated['status'])) {
            $query->where('order_status', $validated['status']);
        }

        $orders = $query->paginate(15);

        return response()->json([
            'success' => true,
            'data'    => $orders->items(),
            'meta'    => [
                'current_page' => $orders->currentPage(),
                'last_page'    => $orders->lastPage(),
                'per_page'     => $orders->perPage(),
                'total'        => $orders->total(),
            ],
        ]);
    }

    /**
     * GET /api/v1/merchant/orders/{id}
     * Detail order untuk mitra.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $order = $request->user()
            ->orders()
            ->with(['items', 'user:id,name,phone', 'delivery'])
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data'    => $order,
        ]);
    }
}
