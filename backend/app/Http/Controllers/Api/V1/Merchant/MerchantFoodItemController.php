<?php

namespace App\Http\Controllers\Api\V1\Merchant;

use App\Http\Controllers\Controller;
use App\Models\FoodItem;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MerchantFoodItemController extends Controller
{
    /**
     * GET /api/v1/merchant/food-items
     * Daftar makanan milik mitra sendiri.
     */
    public function index(Request $request): JsonResponse
    {
        $merchant = $request->user();
        $items    = $merchant->foodItems()->latest()->paginate(20);

        return response()->json([
            'success' => true,
            'data'    => $items->items(),
            'meta'    => [
                'current_page' => $items->currentPage(),
                'last_page'    => $items->lastPage(),
                'per_page'     => $items->perPage(),
                'total'        => $items->total(),
            ],
        ]);
    }

    /**
     * POST /api/v1/merchant/food-items
     * Upload makanan baru (Quick Upload).
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name'         => ['required', 'string', 'max:150'],
            'description'  => ['nullable', 'string'],
            'image'        => ['required', 'image', 'max:5120'],
            'original_price'=> ['required', 'numeric', 'min:1000'],
            'rescue_price' => ['required', 'numeric', 'min:500'],
            'quantity'     => ['required', 'integer', 'min:1'],
            'reason'       => ['nullable', 'string'],
            'produced_at'  => ['nullable', 'date'],
            'expires_at'   => ['required', 'date', 'after:now'],
            'pickup_only'  => ['sometimes', 'boolean'],
            'is_flash_sale'     => ['sometimes', 'boolean'],
            'flash_sale_ends_at'=> ['nullable', 'date', 'after:now'],
        ]);

        // Validate rescue price < original price
        if ($validated['rescue_price'] >= $validated['original_price']) {
            return response()->json([
                'success' => false,
                'message' => 'Harga rescue harus lebih rendah dari harga asli.',
            ], 422);
        }

        $imagePath = $request->file('image')->store('food', 'public');

        // Auto-calculate discount_pct
        $discountPct = (int) round(
            ($validated['original_price'] - $validated['rescue_price'])
            / $validated['original_price'] * 100
        );

        $item = $request->user()->foodItems()->create([
            'name'           => $validated['name'],
            'description'    => $validated['description'] ?? null,
            'image'          => $imagePath,
            'original_price' => $validated['original_price'],
            'rescue_price'   => $validated['rescue_price'],
            'discount_pct'   => $discountPct,
            'quantity'       => $validated['quantity'],
            'reason'         => $validated['reason'] ?? null,
            'produced_at'    => $validated['produced_at'] ?? null,
            'expires_at'     => $validated['expires_at'],
            'pickup_only'    => $validated['pickup_only'] ?? false,
            'is_flash_sale'  => $validated['is_flash_sale'] ?? false,
            'flash_sale_ends_at' => $validated['flash_sale_ends_at'] ?? null,
            'status'         => 'available',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Makanan berhasil dipublikasikan',
            'data'    => $item,
        ], 201);
    }

    /**
     * PUT /api/v1/merchant/food-items/{id}
     * Edit detail makanan.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $merchant = $request->user();
        $item     = $merchant->foodItems()->findOrFail($id);

        $validated = $request->validate([
            'name'          => ['sometimes', 'string', 'max:150'],
            'description'   => ['sometimes', 'nullable', 'string'],
            'image'         => ['sometimes', 'image', 'max:5120'],
            'original_price'=> ['sometimes', 'numeric', 'min:1000'],
            'rescue_price'  => ['sometimes', 'numeric', 'min:500'],
            'quantity'      => ['sometimes', 'integer', 'min:0'],
            'reason'        => ['sometimes', 'nullable', 'string'],
            'produced_at'   => ['sometimes', 'nullable', 'date'],
            'expires_at'    => ['sometimes', 'date', 'after:now'],
            'pickup_only'   => ['sometimes', 'boolean'],
            'status'        => ['sometimes', 'in:available,sold_out,cancelled'],
            'is_flash_sale'      => ['sometimes', 'boolean'],
            'flash_sale_ends_at' => ['nullable', 'date', 'after:now'],
        ]);

        if ($request->hasFile('image')) {
            $validated['image'] = $request->file('image')->store('food', 'public');
        }

        // Recalculate discount_pct if price changed
        $originalPrice = $validated['original_price'] ?? $item->original_price;
        $rescuePrice   = $validated['rescue_price'] ?? $item->rescue_price;

        if (isset($validated['original_price']) || isset($validated['rescue_price'])) {
            if ($rescuePrice >= $originalPrice) {
                return response()->json([
                    'success' => false,
                    'message' => 'Harga rescue harus lebih rendah dari harga asli.',
                ], 422);
            }
            $validated['discount_pct'] = (int) round(($originalPrice - $rescuePrice) / $originalPrice * 100);
        }

        $item->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Makanan berhasil diperbarui',
            'data'    => $item->fresh(),
        ]);
    }

    /**
     * PATCH /api/v1/merchant/food-items/{id}/stock
     * Update stok saja (cepat).
     */
    public function updateStock(Request $request, int $id): JsonResponse
    {
        $merchant = $request->user();
        $item     = $merchant->foodItems()->findOrFail($id);

        $validated = $request->validate([
            'quantity' => ['required', 'integer', 'min:0'],
        ]);

        $item->update([
            'quantity' => $validated['quantity'],
            'status'   => $validated['quantity'] > 0 ? 'available' : 'sold_out',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Stok berhasil diperbarui',
            'data'    => ['quantity' => $item->fresh()->quantity, 'status' => $item->fresh()->status],
        ]);
    }

    /**
     * DELETE /api/v1/merchant/food-items/{id}
     * Hapus/cancel listing makanan.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $merchant = $request->user();
        $item     = $merchant->foodItems()->findOrFail($id);

        $item->update(['status' => 'cancelled']);

        return response()->json([
            'success' => true,
            'message' => 'Listing makanan telah dibatalkan',
        ]);
    }
}
