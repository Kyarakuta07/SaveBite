<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Order;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class WebhookController extends Controller
{
    /**
     * POST /api/v1/webhooks/midtrans
     * Callback status pembayaran dari Midtrans.
     */
    public function midtrans(Request $request): JsonResponse
    {
        // 1. Verify Midtrans signature
        $serverKey = config('services.midtrans.server_key');
        $orderId   = $request->input('order_id');
        $statusCode = $request->input('status_code');
        $grossAmount = $request->input('gross_amount');
        $signature  = $request->input('signature_key');

        $expectedSignature = hash('sha512', $orderId . $statusCode . $grossAmount . $serverKey);

        if ($signature !== $expectedSignature) {
            Log::warning('Midtrans webhook: invalid signature', ['order_id' => $orderId]);
            return response()->json(['message' => 'Invalid signature.'], 403);
        }

        return DB::transaction(function () use ($orderId, $request): JsonResponse {
            // Lock order row to prevent concurrent webhook race condition
            $order = Order::where('order_code', $orderId)->lockForUpdate()->first();

            if (! $order) {
                return response()->json(['message' => 'Order not found.'], 404);
            }

            $transactionStatus = $request->input('transaction_status');

            // 2. Handle settlement (success) — idempotent: skip if already processed
            if (in_array($transactionStatus, ['settlement', 'capture'])) {
                if ($order->payment_status !== 'pending') {
                    return response()->json(['message' => 'Already processed.']);
                }

                $order->update([
                    'payment_status' => 'paid',
                    'order_status'   => 'confirmed',
                    'paid_at'        => now(),
                ]);

                // TODO: dispatch logistics job
                // DispatchLogistics::dispatch($order);

                Log::info('Midtrans webhook: payment confirmed', ['order_code' => $orderId]);
            }

            // 3. Handle pending (do nothing)
            if ($transactionStatus === 'pending') {
                Log::info('Midtrans webhook: payment pending', ['order_code' => $orderId]);
            }

            // 4. Handle failure / cancel — idempotent: skip if already processed
            if (in_array($transactionStatus, ['deny', 'cancel', 'expire', 'failure'])) {
                if ($order->payment_status !== 'pending') {
                    return response()->json(['message' => 'Already processed.']);
                }

                $order->update([
                    'payment_status' => 'failed',
                    'order_status'   => 'cancelled',
                ]);

                // Restore stock (runs only once due to lock + idempotency guard)
                foreach ($order->items as $item) {
                    \App\Models\FoodItem::where('id', $item->food_item_id)->increment('quantity', $item->quantity);
                }

                Log::info('Midtrans webhook: payment failed/cancelled', ['order_code' => $orderId]);
            }

            return response()->json(['message' => 'OK']);
        });
    }

    /**
     * POST /api/v1/webhooks/delivery
     * Callback status pengiriman dari kurir API.
     */
    public function delivery(Request $request): JsonResponse
    {
        // Verify API key from logistics provider
        $expectedKey = config('services.logistics.webhook_key', 'savebite-delivery-key');
        $receivedKey = $request->header('X-Delivery-Webhook-Key');

        if ($receivedKey !== $expectedKey) {
            return response()->json(['message' => 'Unauthorized.'], 401);
        }

        $trackingId = $request->input('tracking_id');
        $newStatus  = $request->input('status'); // searching|driver_found|picked_up|on_the_way|delivered|failed
        $driverInfo = $request->input('driver');

        $delivery = \App\Models\Delivery::where('tracking_id', $trackingId)->first();

        if (! $delivery) {
            return response()->json(['message' => 'Delivery not found.'], 404);
        }

        $updateData = ['status' => $newStatus];

        if ($driverInfo) {
            $updateData['driver_name']    = $driverInfo['name'] ?? null;
            $updateData['driver_phone']   = $driverInfo['phone'] ?? null;
            $updateData['driver_vehicle'] = $driverInfo['vehicle'] ?? null;
        }

        if ($request->has('tracking_url')) {
            $updateData['live_tracking_url'] = $request->input('tracking_url');
        }

        if ($request->has('estimated_arrival')) {
            $updateData['estimated_arrival'] = $request->input('estimated_arrival');
        }

        $delivery->update($updateData);

        // Update order status when delivered
        if ($newStatus === 'delivered') {
            $delivery->order->update(['order_status' => 'delivered']);
            // TODO: schedule auto-complete after 1 hour
            // AutoCompleteOrder::dispatch($delivery->order)->delay(now()->addHour());
        }

        // Handle failed delivery → notify user to choose self-pickup
        if ($newStatus === 'failed') {
            // Store failure info in api_response JSON column
            $delivery->update(['api_response' => ['reason' => $request->input('reason', 'Driver tidak ditemukan')]]);
            // TODO: push notification to user
        }

        Log::info('Delivery webhook received', ['tracking_id' => $trackingId, 'status' => $newStatus]);

        return response()->json(['message' => 'OK']);
    }
}
