<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\User;
use App\Models\WalletTransaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class WebhookController extends Controller
{
    /**
     * POST /api/v1/webhooks/midtrans
     * Callback status pembayaran dari Midtrans.
     *
     * Handles two types of payments:
     * 1. Order payments (order_id starts with "SB-")
     * 2. Wallet top-ups (order_id starts with "WLT-")
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

        $transactionStatus = $request->input('transaction_status');

        // 2. Route to correct handler based on reference type
        if (str_starts_with($orderId, 'WLT-')) {
            return $this->handleTopUpWebhook($orderId, $transactionStatus);
        }

        return $this->handleOrderWebhook($orderId, $transactionStatus);
    }

    /**
     * Handle order payment webhook callback.
     */
    private function handleOrderWebhook(string $orderId, string $transactionStatus): JsonResponse
    {
        return DB::transaction(function () use ($orderId, $transactionStatus): JsonResponse {
            // Lock order row to prevent concurrent webhook race condition
            $order = Order::where('order_code', $orderId)->lockForUpdate()->first();

            if (! $order) {
                return response()->json(['message' => 'Order not found.'], 404);
            }

            // Handle settlement (success) — idempotent: skip if already processed
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

            // Handle pending (do nothing)
            if ($transactionStatus === 'pending') {
                Log::info('Midtrans webhook: payment pending', ['order_code' => $orderId]);
            }

            // Handle failure / cancel — idempotent: skip if already processed
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
     * Handle wallet top-up webhook callback.
     *
     * When Midtrans confirms a top-up payment, we:
     * 1. Find the PENDING WalletTransaction by reference code
     * 2. Credit the user's wallet balance atomically
     * 3. Update the transaction record to CONFIRMED
     */
    private function handleTopUpWebhook(string $referenceCode, string $transactionStatus): JsonResponse
    {
        return DB::transaction(function () use ($referenceCode, $transactionStatus): JsonResponse {
            // Find the pending top-up transaction by description match
            $tx = WalletTransaction::where('type', 'topup')
                ->where('description', 'like', 'PENDING:%')
                ->where('reference_type', 'topup')
                ->lockForUpdate()
                ->latest()
                ->first();

            if (! $tx) {
                Log::warning('Midtrans webhook: top-up transaction not found', ['reference' => $referenceCode]);
                return response()->json(['message' => 'Transaction not found.'], 404);
            }

            // Settlement — credit the wallet
            if (in_array($transactionStatus, ['settlement', 'capture'])) {
                // Idempotency: skip if already confirmed
                if (! str_starts_with($tx->description, 'PENDING:')) {
                    return response()->json(['message' => 'Already processed.']);
                }

                // Lock user row and credit balance
                $user = User::where('id', $tx->owner_id)->lockForUpdate()->first();

                $tx->update([
                    'balance_after'  => $user->wallet_balance + $tx->amount,
                    'reference_id'   => crc32($referenceCode), // Store reference for audit
                    'description'    => str_replace('PENDING: ', 'CONFIRMED: ', $tx->description),
                ]);

                $user->increment('wallet_balance', $tx->amount);

                Log::info('Midtrans webhook: top-up confirmed', [
                    'user_id' => $user->id,
                    'amount'  => $tx->amount,
                    'reference' => $referenceCode,
                ]);
            }

            // Failure — mark as failed
            if (in_array($transactionStatus, ['deny', 'cancel', 'expire', 'failure'])) {
                if (! str_starts_with($tx->description, 'PENDING:')) {
                    return response()->json(['message' => 'Already processed.']);
                }

                $tx->update([
                    'description' => str_replace('PENDING: ', 'FAILED: ', $tx->description),
                ]);

                Log::info('Midtrans webhook: top-up failed', ['reference' => $referenceCode]);
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
