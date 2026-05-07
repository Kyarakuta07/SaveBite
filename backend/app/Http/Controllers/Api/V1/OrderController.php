<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Models\FoodItem;
use App\Models\Merchant;
use App\Models\Order;
use App\Models\User;
use App\Models\WalletTransaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{
    /**
     * POST /api/v1/orders
     * Buat order baru (checkout).
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'merchant_id'      => ['required', 'integer', 'exists:merchants,id'],
            'items'            => ['required', 'array', 'min:1'],
            'items.*.food_item_id' => ['required', 'integer', 'exists:food_items,id'],
            'items.*.quantity' => ['required', 'integer', 'min:1'],
            'payment_method'   => ['required', 'in:wallet,qris,e_wallet,bank_transfer'],
            'delivery_address' => ['required_if:payment_method,qris,e_wallet,bank_transfer', 'nullable', 'string'],
            'delivery_lat'     => ['nullable', 'numeric'],
            'delivery_lng'     => ['nullable', 'numeric'],
            'notes'            => ['nullable', 'string', 'max:500'],
        ]);

        // Validate merchant is active (prevent checkout to suspended/banned merchants)
        $checkMerchant = Merchant::findOrFail($validated['merchant_id']);
        if ($checkMerchant->status !== 'active') {
            return response()->json([
                'success' => false,
                'message' => 'Mitra ini sedang tidak aktif.',
            ], 422);
        }

        $user       = $request->user();
        $orderItems = [];
        $subtotal   = 0;
        $savings    = 0;

        return DB::transaction(function () use ($validated, $user, &$orderItems, &$subtotal, &$savings): JsonResponse {
            // 1. Validate all food items belong to the given merchant & are available
            foreach ($validated['items'] as $lineItem) {
                $foodItem = FoodItem::where('id', $lineItem['food_item_id'])
                    ->where('merchant_id', $validated['merchant_id'])
                    ->where('status', 'available')
                    ->lockForUpdate()
                    ->firstOrFail();

                if ($foodItem->quantity < $lineItem['quantity']) {
                    return response()->json([
                        'success' => false,
                        'message' => "Stok '{$foodItem->name}' tidak cukup (tersisa {$foodItem->quantity}).",
                    ], 422);
                }

                $lineSubtotal = $foodItem->rescue_price * $lineItem['quantity'];
                $lineSavings  = ($foodItem->original_price - $foodItem->rescue_price) * $lineItem['quantity'];

                $subtotal += $lineSubtotal;
                $savings  += $lineSavings;

                $orderItems[] = [
                    'food_item_id'   => $foodItem->id,
                    'food_name'      => $foodItem->name,
                    'original_price' => $foodItem->original_price,
                    'rescue_price'   => $foodItem->rescue_price,
                    'quantity'       => $lineItem['quantity'],
                    'line_total'     => $lineSubtotal,
                ];

                // Deduct stock immediately
                $foodItem->decrement('quantity', $lineItem['quantity']);
                if ($foodItem->fresh()->quantity === 0) {
                    $foodItem->update(['status' => 'sold_out']);
                }
            }

            // 2. Delivery fee (mock/fixed for now, real = from logistics API)
            $deliveryFee = 12000.00;

            // 3. Commission from app_settings
            $commissionRate = (float) AppSetting::getValue('commission_rate', 5);
            $commissionFee  = round($subtotal * ($commissionRate / 100), 2);

            // 4. Total (delivery fee added, commission is internal)
            $totalAmount = $subtotal + $deliveryFee;

            // 5. Handle wallet payment (with row lock to prevent double-spend)
            $walletBalanceBefore = null;
            if ($validated['payment_method'] === 'wallet') {
                $user = User::where('id', $user->id)->lockForUpdate()->first();
                if ($user->wallet_balance < $totalAmount) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Saldo wallet tidak mencukupi.',
                    ], 422);
                }
                $walletBalanceBefore = $user->wallet_balance;
                $user->decrement('wallet_balance', $totalAmount);
            }

            // 6. Create the order
            $order = Order::create([
                'order_code'       => Order::generateOrderCode(),
                'user_id'          => $user->id,
                'merchant_id'      => $validated['merchant_id'],
                'subtotal'         => $subtotal,
                'delivery_fee'     => $deliveryFee,
                'commission_fee'   => $commissionFee,
                'total_amount'     => $totalAmount,
                'savings_amount'   => $savings,
                'payment_method'   => $validated['payment_method'],
                'payment_status'   => $validated['payment_method'] === 'wallet' ? 'paid' : 'pending',
                'order_status'     => $validated['payment_method'] === 'wallet' ? 'confirmed' : 'pending',
                'delivery_address' => $validated['delivery_address'] ?? null,
                'delivery_lat'     => $validated['delivery_lat'] ?? null,
                'delivery_lng'     => $validated['delivery_lng'] ?? null,
                'notes'            => $validated['notes'] ?? null,
                'paid_at'          => $validated['payment_method'] === 'wallet' ? now() : null,
            ]);

            // 7. Create order items
            foreach ($orderItems as $item) {
                $order->items()->create($item);
            }

            // 8. If wallet payment: record transaction + dispatch logistics
            $paymentData = null;
            if ($validated['payment_method'] === 'wallet') {
                WalletTransaction::create([
                    'owner_type'     => 'user',
                    'owner_id'       => $user->id,
                    'type'           => 'payment',
                    'amount'         => $totalAmount,
                    'balance_before' => $walletBalanceBefore,
                    'balance_after'  => $user->fresh()->wallet_balance,
                    'reference_type' => 'order',
                    'reference_id'   => $order->id,
                    'description'    => "Pembayaran order {$order->order_code}",
                ]);

                // TODO: dispatch logistics job here
                // DispatchLogistics::dispatch($order);
            } else {
                // TODO: Create Midtrans payment → return payment_url
                $paymentData = [
                    'payment_url' => 'https://app.midtrans.com/snap/v2/placeholder/' . $order->order_code,
                    'payment_type' => $validated['payment_method'],
                    'expires_at'   => now()->addMinutes(15)->toIso8601String(),
                ];
            }

            $response = [
                'success' => true,
                'message' => 'Order berhasil dibuat',
                'data'    => ['order' => $order],
            ];

            if ($paymentData) {
                $response['data']['payment'] = $paymentData;
            }

            return response()->json($response, 201);
        });
    }

    /**
     * GET /api/v1/orders
     * Riwayat order user.
     */
    public function index(Request $request): JsonResponse
    {
        $orders = $request->user()
            ->orders()
            ->with(['items', 'merchant:id,display_name,is_anonymous,logo'])
            ->latest()
            ->paginate(15);

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
     * GET /api/v1/orders/{id}
     * Detail order + delivery tracking.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $order = $request->user()
            ->orders()
            ->with(['items', 'merchant:id,display_name,is_anonymous,logo,category', 'delivery', 'dispute', 'review'])
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data'    => $order,
        ]);
    }

    /**
     * POST /api/v1/orders/{id}/complete
     * Konfirmasi order selesai (manual oleh user).
     * Transfers funds: user payment → merchant income + platform commission.
     */
    public function complete(Request $request, int $id): JsonResponse
    {
        $order = $request->user()->orders()->with('items')->findOrFail($id);

        if ($order->order_status !== 'delivered') {
            return response()->json([
                'success' => false,
                'message' => 'Order belum dalam status terkirim.',
            ], 422);
        }

        DB::transaction(function () use ($order): void {
            $order->update([
                'order_status' => 'completed',
                'completed_at' => now(),
            ]);

            // 1. Transfer pendapatan ke merchant wallet (subtotal - komisi)
            $merchant = Merchant::where('id', $order->merchant_id)->lockForUpdate()->first();
            $merchantAmount = $order->subtotal - $order->commission_fee;

            WalletTransaction::create([
                'owner_type'     => 'merchant',
                'owner_id'       => $merchant->id,
                'type'           => 'income',
                'amount'         => $merchantAmount,
                'balance_before' => $merchant->wallet_balance,
                'balance_after'  => $merchant->wallet_balance + $merchantAmount,
                'reference_type' => 'order',
                'reference_id'   => $order->id,
                'description'    => "Pendapatan order {$order->order_code}",
            ]);
            $merchant->increment('wallet_balance', $merchantAmount);

            // 2. Catat komisi platform
            WalletTransaction::create([
                'owner_type'     => 'platform',
                'owner_id'       => 0,
                'type'           => 'commission',
                'amount'         => $order->commission_fee,
                'balance_before' => 0,
                'balance_after'  => 0,
                'reference_type' => 'order',
                'reference_id'   => $order->id,
                'description'    => "Komisi order {$order->order_code}",
            ]);

            // 3. Update gamification user
            $user = $order->user;
            $user->increment('total_saved', $order->savings_amount);
            $user->increment('total_rescued', $order->items->sum('quantity'));
        });

        return response()->json([
            'success' => true,
            'message' => 'Order berhasil dikonfirmasi selesai. Terima kasih telah menyelamatkan makanan!',
        ]);
    }

    /**
     * POST /api/v1/orders/{id}/cancel
     * Batalkan order (hanya status confirmed, sebelum kurir pickup).
     */
    public function cancel(Request $request, int $id): JsonResponse
    {
        $order = $request->user()->orders()->with('items')->findOrFail($id);

        if ($order->order_status !== 'confirmed') {
            return response()->json([
                'success' => false,
                'message' => 'Order tidak dapat dibatalkan pada status saat ini.',
            ], 422);
        }

        DB::transaction(function () use ($order): void {
            // 1. Restore stock
            foreach ($order->items as $item) {
                FoodItem::where('id', $item->food_item_id)->increment('quantity', $item->quantity);
            }

            // 2. Refund to wallet with audit trail
            $user = User::where('id', $order->user_id)->lockForUpdate()->first();

            WalletTransaction::create([
                'owner_type'     => 'user',
                'owner_id'       => $user->id,
                'type'           => 'refund',
                'amount'         => $order->total_amount,
                'balance_before' => $user->wallet_balance,
                'balance_after'  => $user->wallet_balance + $order->total_amount,
                'reference_type' => 'order',
                'reference_id'   => $order->id,
                'description'    => "Refund order {$order->order_code}",
            ]);

            $user->increment('wallet_balance', $order->total_amount);

            // 3. Update order status
            $order->update([
                'order_status'   => 'cancelled',
                'payment_status' => 'refunded',
            ]);
        });

        return response()->json([
            'success' => true,
            'message' => 'Order berhasil dibatalkan. Refund telah dikembalikan ke wallet Anda.',
        ]);
    }

    /**
     * POST /api/v1/orders/{id}/reorder
     * "Pesan Lagi" — clone order lama ke cart items baru yang masih available.
     */
    public function reorder(Request $request, int $id): JsonResponse
    {
        $originalOrder = $request->user()
            ->orders()
            ->with('items.foodItem')
            ->findOrFail($id);

        // Kumpulkan item yang masih available dari order lama
        $availableItems = [];
        $unavailableNames = [];

        foreach ($originalOrder->items as $item) {
            $food = $item->foodItem;

            if ($food && $food->status === 'available' && $food->quantity > 0) {
                $availableItems[] = [
                    'food_item_id' => $food->id,
                    'name'         => $food->name,
                    'rescue_price' => $food->rescue_price,
                    'quantity'     => min($item->quantity, $food->quantity), // batasi ke stok sisa
                    'image'        => $food->image,
                ];
            } else {
                $unavailableNames[] = $item->foodItem?->name ?? "Item #{$item->food_item_id}";
            }
        }

        if (empty($availableItems)) {
            return response()->json([
                'success' => false,
                'message' => 'Semua item dari pesanan ini sudah tidak tersedia.',
            ], 422);
        }

        return response()->json([
            'success'           => true,
            'message'           => empty($unavailableNames)
                ? 'Semua item siap dipesan kembali.'
                : 'Beberapa item tidak tersedia: ' . implode(', ', $unavailableNames),
            'data'              => [
                'merchant_id'       => $originalOrder->merchant_id,
                'available_items'   => $availableItems,
                'unavailable_items' => $unavailableNames,
            ],
        ]);
    }
}
