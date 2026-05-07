<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Merchant;
use App\Models\WalletTransaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class WalletController extends Controller
{
    /**
     * GET /api/v1/me/wallet
     * Saldo wallet + ringkasan.
     */
    public function userWallet(Request $request): JsonResponse
    {
        $user = $request->user();

        $totalTopUp = WalletTransaction::where('owner_type', 'user')
            ->where('owner_id', $user->id)
            ->where('type', 'topup')
            ->sum('amount');

        $totalSpent = WalletTransaction::where('owner_type', 'user')
            ->where('owner_id', $user->id)
            ->where('type', 'payment')
            ->sum('amount');

        return response()->json([
            'success' => true,
            'data'    => [
                'balance'      => $user->wallet_balance,
                'total_top_up' => $totalTopUp,
                'total_spent'  => $totalSpent,
            ],
        ]);
    }

    /**
     * POST /api/v1/me/wallet/topup
     * Request top-up (return payment URL).
     */
    public function topup(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'amount'         => ['required', 'integer', 'min:10000', 'max:10000000'],
            'payment_method' => ['required', 'in:qris,e_wallet,bank_transfer'],
        ]);

        $user = $request->user();

        // Create pending wallet transaction
        $tx = WalletTransaction::create([
            'owner_type'     => 'user',
            'owner_id'       => $user->id,
            'type'           => 'topup',
            'amount'         => $validated['amount'],
            'balance_before' => $user->wallet_balance,
            'balance_after'  => $user->wallet_balance, // Updated when payment confirmed
            'reference_type' => 'topup',
            'reference_id'   => null,
            'description'    => 'Top-up wallet via ' . strtoupper($validated['payment_method']),
        ]);

        // TODO: Create Midtrans payment → return payment_url
        $referenceCode = 'WLT-' . now()->format('Ymd') . '-' . strtoupper(substr(md5(uniqid()), 0, 6));
        $paymentUrl = 'https://app.midtrans.com/snap/v2/placeholder/' . $referenceCode;

        return response()->json([
            'success' => true,
            'data'    => [
                'transaction_id' => $tx->id,
                'reference_code' => $referenceCode,
                'amount'         => $validated['amount'],
                'payment_url'    => $paymentUrl,
                'expires_at'     => now()->addMinutes(30)->toIso8601String(),
            ],
        ]);
    }

    /**
     * GET /api/v1/me/wallet/transactions
     * Riwayat mutasi saldo user.
     */
    public function userTransactions(Request $request): JsonResponse
    {
        $transactions = WalletTransaction::where('owner_type', 'user')
            ->where('owner_id', $request->user()->id)
            ->latest('created_at')
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data'    => $transactions->items(),
            'meta'    => [
                'current_page' => $transactions->currentPage(),
                'last_page'    => $transactions->lastPage(),
                'per_page'     => $transactions->perPage(),
                'total'        => $transactions->total(),
            ],
        ]);
    }

    /**
     * GET /api/v1/merchant/wallet
     * Saldo wallet mitra.
     */
    public function merchantWallet(Request $request): JsonResponse
    {
        $merchant = $request->user();

        return response()->json([
            'success' => true,
            'data'    => [
                'balance'     => $merchant->wallet_balance,
                'is_verified' => $merchant->is_verified,
                'status'      => $merchant->status,
            ],
        ]);
    }

    /**
     * GET /api/v1/merchant/wallet/transactions
     * Riwayat mutasi mitra.
     */
    public function merchantTransactions(Request $request): JsonResponse
    {
        $transactions = WalletTransaction::where('owner_type', 'merchant')
            ->where('owner_id', $request->user()->id)
            ->latest('created_at')
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data'    => $transactions->items(),
            'meta'    => [
                'current_page' => $transactions->currentPage(),
                'last_page'    => $transactions->lastPage(),
                'per_page'     => $transactions->perPage(),
                'total'        => $transactions->total(),
            ],
        ]);
    }

    /**
     * POST /api/v1/merchant/wallet/withdraw
     * Request penarikan saldo mitra.
     */
    public function withdraw(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'amount'       => ['required', 'integer', 'min:50000'],
            'bank_code'    => ['required', 'string', 'max:10'],
            'bank_account' => ['required', 'string', 'max:30'],
            'bank_name'    => ['required', 'string', 'max:100'],
        ]);

        return DB::transaction(function () use ($request, $validated): JsonResponse {
            // Lock merchant row to prevent double-withdraw race condition
            $merchant = Merchant::where('id', $request->user()->id)->lockForUpdate()->first();

            if ($merchant->wallet_balance < $validated['amount']) {
                return response()->json([
                    'success' => false,
                    'message' => 'Saldo tidak mencukupi untuk penarikan.',
                ], 422);
            }

            $balanceBefore = $merchant->wallet_balance;
            $balanceAfter  = $balanceBefore - $validated['amount'];

            // Create withdrawal transaction
            $tx = WalletTransaction::create([
                'owner_type'     => 'merchant',
                'owner_id'       => $merchant->id,
                'type'           => 'withdrawal',
                'amount'         => $validated['amount'],
                'balance_before' => $balanceBefore,
                'balance_after'  => $balanceAfter,
                'reference_type' => 'withdrawal',
                'reference_id'   => null,
                'description'    => "Penarikan ke {$validated['bank_name']} - {$validated['bank_account']}",
            ]);

            // Deduct the balance
            $merchant->decrement('wallet_balance', $validated['amount']);

            return response()->json([
                'success' => true,
                'message' => 'Permintaan penarikan berhasil diajukan. Proses 1-3 hari kerja.',
                'data'    => [
                    'transaction_id' => $tx->id,
                    'amount'         => $validated['amount'],
                    'status'         => 'pending',
                ],
            ], 201);
        });
    }
}
