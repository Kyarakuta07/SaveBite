<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\FoodItem;
use App\Models\Merchant;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FoodItemController extends Controller
{
    /**
     * GET /api/v1/food-items
     * Daftar makanan tersedia dengan filter, sort, dan pagination.
     */
    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'lat'      => ['nullable', 'numeric'],
            'lng'      => ['nullable', 'numeric'],
            'radius'   => ['nullable', 'integer', 'min:1', 'max:100'],
            'category' => ['nullable', 'in:fast_food,bakery,supermarket'],
            'search'   => ['nullable', 'string', 'max:100'],
            'sort_by'  => ['nullable', 'in:distance,price,newest'],
            'page'     => ['nullable', 'integer', 'min:1'],
        ]);

        $query = FoodItem::query()
            ->with(['merchant:id,display_name,is_anonymous,category,average_rating,total_reviews,latitude,longitude'])
            ->where('status', 'available')
            ->whereHas('merchant', fn ($q) => $q->where('status', 'active'));

        // Filter by category
        if (! empty($validated['category'])) {
            $query->whereHas('merchant', fn ($q) => $q->where('category', $validated['category']));
        }

        // Search by food name
        if (! empty($validated['search'])) {
            $query->where('name', 'like', '%' . $validated['search'] . '%');
        }

        // Sort
        $sortBy = $validated['sort_by'] ?? 'newest';
        match ($sortBy) {
            'price'   => $query->orderBy('rescue_price', 'asc'),
            'newest'  => $query->orderByDesc('created_at'),
            default   => $query->orderByDesc('created_at'), // distance sorting done in-app for now
        };

        $perPage = 15;
        $items   = $query->paginate($perPage);

        $data = $items->map(function ($item) use ($validated) {
            $merchant       = $item->merchant;
            $displayName    = $merchant->is_anonymous
                ? ($merchant->display_name ?? 'Toko Anonim #' . $merchant->id)
                : $merchant->display_name ?? $merchant->name; // never expose real name for anonymous

            $distanceKm = null;
            if (! empty($validated['lat']) && ! empty($validated['lng'])) {
                $distanceKm = $this->haversine(
                    $validated['lat'],
                    $validated['lng'],
                    $merchant->latitude,
                    $merchant->longitude
                );
            }

            return [
                'id'             => $item->id,
                'merchant'       => [
                    'id'             => $merchant->id,
                    'display_name'   => $displayName,
                    'is_anonymous'   => $merchant->is_anonymous,
                    'category'       => $merchant->category,
                    'average_rating' => $merchant->average_rating,
                    'total_reviews'  => $merchant->total_reviews,
                    'distance_km'    => $distanceKm ? round($distanceKm, 1) : null,
                ],
                'name'           => $item->name,
                'description'    => $item->description,
                'image'          => $item->image ? asset('storage/' . $item->image) : null,
                'original_price' => $item->original_price,
                'rescue_price'   => $item->rescue_price,
                'discount_pct'   => $item->discount_pct,
                'quantity'       => $item->quantity,
                'quantity_sold'  => $item->quantity_sold,
                'reason'         => $item->reason,
                'produced_at'    => $item->produced_at,
                'expires_at'     => $item->expires_at,
                'status'         => $item->status,
            ];
        });

        return response()->json([
            'success' => true,
            'data'    => $data,
            'meta'    => [
                'current_page' => $items->currentPage(),
                'last_page'    => $items->lastPage(),
                'per_page'     => $items->perPage(),
                'total'        => $items->total(),
            ],
        ]);
    }

    /**
     * GET /api/v1/food-items/{id}
     * Detail satu makanan.
     */
    public function show(int $id): JsonResponse
    {
        $item = FoodItem::with('merchant')->findOrFail($id);

        $merchant    = $item->merchant;
        $displayName = $merchant->is_anonymous
            ? ($merchant->display_name ?? 'Toko Anonim #' . $merchant->id)
            : ($merchant->display_name ?? $merchant->name);

        return response()->json([
            'success' => true,
            'data'    => [
                'id'       => $item->id,
                'merchant' => [
                    'id'             => $merchant->id,
                    'display_name'   => $displayName,
                    'is_anonymous'   => $merchant->is_anonymous,
                    'category'       => $merchant->category,
                    'average_rating' => $merchant->average_rating,
                    'total_reviews'  => $merchant->total_reviews,
                ],
                'name'           => $item->name,
                'description'    => $item->description,
                'image'          => $item->image ? asset('storage/' . $item->image) : null,
                'original_price' => $item->original_price,
                'rescue_price'   => $item->rescue_price,
                'discount_pct'   => $item->discount_pct,
                'quantity'       => $item->quantity,
                'quantity_sold'  => $item->quantity_sold,
                'reason'         => $item->reason,
                'produced_at'    => $item->produced_at,
                'expires_at'     => $item->expires_at,
                'pickup_only'    => $item->pickup_only,
                'status'         => $item->status,
            ],
        ]);
    }

    /**
     * GET /api/v1/merchants/{id}
     * Profil publik toko (untuk user).
     */
    public function merchantProfile(int $id): JsonResponse
    {
        $merchant = Merchant::findOrFail($id);

        // Anonymous merchants: do NOT expose real name or address
        $displayName = $merchant->is_anonymous
            ? ($merchant->display_name ?? 'Toko Anonim #' . $merchant->id)
            : ($merchant->display_name ?? $merchant->name);

        return response()->json([
            'success' => true,
            'data'    => [
                'id'               => $merchant->id,
                'display_name'     => $displayName,
                'is_anonymous'     => $merchant->is_anonymous,
                'category'         => $merchant->category,
                'logo'             => $merchant->logo ? asset('storage/' . $merchant->logo) : null,
                'average_rating'   => $merchant->average_rating,
                'total_reviews'    => $merchant->total_reviews,
                'operational_hours'=> $merchant->operational_hours,
                // Only share address to non-anonymous merchants
                'address'          => $merchant->is_anonymous ? null : $merchant->address,
                'latitude'         => $merchant->is_anonymous ? null : $merchant->latitude,
                'longitude'        => $merchant->is_anonymous ? null : $merchant->longitude,
            ],
        ]);
    }

    // ─── Haversine distance formula ──────────────────────────────────────
    private function haversine(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $earthRadius = 6371; // km
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a    = sin($dLat / 2) ** 2
              + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;

        return $earthRadius * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }

    /**
     * GET /api/v1/food-items/flash-sale
     * Daftar item flash sale aktif, diurutkan berdasarkan waktu berakhir terdekat.
     * Mendukung countdown timer di UI Beranda.
     */
    public function flashSale(Request $request): JsonResponse
    {
        $items = FoodItem::flashSale()
            ->with(['merchant:id,display_name,name,is_anonymous,category,latitude,longitude'])
            ->orderBy('flash_sale_ends_at')
            ->take(20)
            ->get()
            ->map(function (FoodItem $item) {
                $data = $item->toArray();

                // Tambah seconds_remaining untuk countdown timer di Flutter
                $data['seconds_remaining'] = $item->flash_sale_ends_at
                    ? max(0, now()->diffInSeconds($item->flash_sale_ends_at, false))
                    : null;

                // Sembunyikan nama asli merchant jika anonymous
                if ($item->merchant && $item->merchant->is_anonymous) {
                    $data['merchant']['name'] = $data['merchant']['display_name'] ?? 'Mitra SaveBite';
                }

                return $data;
            });

        return response()->json([
            'success' => true,
            'data'    => $items,
            'meta'    => [
                'total'         => $items->count(),
                'server_time'   => now()->toIso8601String(),
            ],
        ]);
    }
}
