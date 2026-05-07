<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Models\Dispute;
use App\Models\Merchant;
use App\Models\MerchantViolation;
use App\Models\Order;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminController extends Controller
{
    /**
     * GET /api/v1/admin/dashboard
     * Statistik: total order, revenue, user aktif.
     */
    public function dashboard(): JsonResponse
    {
        $today  = now()->toDateString();
        $month  = now()->format('Y-m');

        return response()->json([
            'success' => true,
            'data'    => [
                'total_users'         => User::count(),
                'total_merchants'     => Merchant::count(),
                'active_merchants'    => Merchant::where('status', 'active')->count(),
                'orders_today'        => Order::whereDate('created_at', $today)->count(),
                'revenue_today'       => Order::whereDate('created_at', $today)
                                             ->where('payment_status', 'paid')
                                             ->sum('commission_fee'),
                'orders_this_month'   => Order::where('created_at', 'like', "{$month}%")->count(),
                'revenue_this_month'  => Order::where('created_at', 'like', "{$month}%")
                                             ->where('payment_status', 'paid')
                                             ->sum('commission_fee'),
                'pending_disputes'    => Dispute::where('status', 'pending')->count(),
                'pending_verifications' => Merchant::where('is_verified', false)->count(),
            ],
        ]);
    }

    /**
     * GET /api/v1/admin/disputes
     * Daftar semua komplain pending.
     */
    public function disputes(Request $request): JsonResponse
    {
        $status  = $request->query('status', 'pending');
        $disputes = Dispute::where('status', $status)
            ->with(['order:id,order_code', 'user:id,name,email', 'merchant:id,name,display_name'])
            ->latest()
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data'    => $disputes->items(),
            'meta'    => [
                'current_page' => $disputes->currentPage(),
                'last_page'    => $disputes->lastPage(),
                'per_page'     => $disputes->perPage(),
                'total'        => $disputes->total(),
            ],
        ]);
    }

    /**
     * PUT /api/v1/admin/disputes/{id}
     * Approve/reject dispute + refund.
     */
    public function resolveDispute(Request $request, int $id): JsonResponse
    {
        $validated = $request->validate([
            'status'        => ['required', 'in:approved,rejected'],
            'admin_notes'   => ['required', 'string', 'max:1000'],
            'refund_amount' => ['required_if:status,approved', 'nullable', 'numeric', 'min:0'],
        ]);

        $dispute = Dispute::with(['order.user', 'merchant'])->findOrFail($id);

        if ($dispute->status !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'Dispute ini sudah diproses.',
            ], 422);
        }

        DB::transaction(function () use ($validated, $dispute, $request): void {
            $dispute->update([
                'status'       => $validated['status'],
                'admin_notes'  => $validated['admin_notes'],
                'resolved_by'  => $request->user()->id,
                'resolved_at'  => now(),
                'refund_amount'=> $validated['refund_amount'] ?? null,
            ]);

            // If approved: refund user + add merchant violation
            if ($validated['status'] === 'approved') {
                $refundAmount = $validated['refund_amount'] ?? 0;

                if ($refundAmount > 0) {
                    $dispute->order->user->increment('wallet_balance', $refundAmount);
                }

                // Add merchant violation
                $violationCount = MerchantViolation::where('merchant_id', $dispute->merchant_id)->count();
                $violationNumber = $violationCount + 1;

                // Determine action based on violation number
                $actionTaken = match ($violationNumber) {
                    1       => 'warning',
                    2       => 'suspended_3d',
                    3       => 'suspended_7d',
                    default => 'banned',
                };

                MerchantViolation::create([
                    'merchant_id'      => $dispute->merchant_id,
                    'dispute_id'       => $dispute->id,
                    'violation_number' => $violationNumber,
                    'action_taken'     => $actionTaken,
                    'notes'            => "Dari dispute #{$dispute->id}: " . $validated['admin_notes'],
                    'actioned_by'      => $request->user()->id,
                ]);

                // Check if merchant should be suspended (max_violation from app_settings)
                $maxViolations = (int) AppSetting::getValue('max_violation', 4);

                $violationCount = MerchantViolation::where('merchant_id', $dispute->merchant_id)->count();

                // Suspension stages: 1=warning, 2=3 days, 3=7 days, 4=banned
                $merchant = $dispute->merchant;
                if ($violationNumber >= $maxViolations) {
                    $merchant->update(['status' => 'banned', 'suspension_until' => null]);
                } elseif ($violationNumber === 3) {
                    $merchant->update(['status' => 'suspended', 'suspension_until' => now()->addDays(7)]);
                } elseif ($violationNumber === 2) {
                    $merchant->update(['status' => 'suspended', 'suspension_until' => now()->addDays(3)]);
                }

                // Update violation_count on merchant
                $merchant->update(['violation_count' => $violationNumber]);
            }
        });

        return response()->json([
            'success' => true,
            'message' => 'Dispute berhasil ' . ($validated['status'] === 'approved' ? 'disetujui' : 'ditolak'),
        ]);
    }

    /**
     * GET /api/v1/admin/merchants
     * Daftar semua mitra.
     */
    public function merchants(Request $request): JsonResponse
    {
        $status    = $request->query('status');
        $merchants = Merchant::when($status, fn ($q) => $q->where('status', $status))
            ->withCount('orders')
            ->latest()
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data'    => $merchants->items(),
            'meta'    => [
                'current_page' => $merchants->currentPage(),
                'last_page'    => $merchants->lastPage(),
                'per_page'     => $merchants->perPage(),
                'total'        => $merchants->total(),
            ],
        ]);
    }

    /**
     * PUT /api/v1/admin/merchants/{id}/verify
     * Verifikasi mitra baru.
     */
    public function verifyMerchant(Request $request, int $id): JsonResponse
    {
        $merchant = Merchant::findOrFail($id);

        if ($merchant->is_verified) {
            return response()->json([
                'success' => false,
                'message' => 'Mitra ini sudah diverifikasi.',
            ], 422);
        }

        $merchant->update([
            'is_verified' => true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Mitra berhasil diverifikasi dan diaktifkan',
        ]);
    }

    /**
     * PUT /api/v1/admin/merchants/{id}/suspend
     * Skors mitra manual.
     */
    public function suspendMerchant(Request $request, int $id): JsonResponse
    {
        $validated = $request->validate([
            'reason'           => ['required', 'string'],
            'suspension_days'  => ['required', 'integer', 'min:1'],
        ]);

        $merchant = Merchant::findOrFail($id);
        $until    = now()->addDays($validated['suspension_days']);

        $merchant->update([
            'status'          => 'suspended',
            'suspension_until'=> $until,
        ]);

        // Log violation
        $violationCount = MerchantViolation::where('merchant_id', $id)->count();
        $violationNumber = $violationCount + 1;

        MerchantViolation::create([
            'merchant_id'      => $id,
            'dispute_id'       => null, // Manual suspension, no dispute
            'violation_number' => $violationNumber,
            'action_taken'     => $validated['suspension_days'] >= 7 ? 'suspended_7d' : 'suspended_3d',
            'notes'            => $validated['reason'],
            'actioned_by'      => $request->user()->id,
        ]);

        $merchant->update(['violation_count' => $violationNumber]);

        return response()->json([
            'success' => true,
            'message' => "Mitra diskors selama {$validated['suspension_days']} hari hingga " . $until->toDateString(),
        ]);
    }

    /**
     * GET /api/v1/admin/violations
     * Riwayat pelanggaran semua mitra.
     */
    public function violations(Request $request): JsonResponse
    {
        $violations = MerchantViolation::with(['merchant:id,name,display_name', 'actionedBy:id,name'])
            ->latest('actioned_at')
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data'    => $violations->items(),
            'meta'    => [
                'current_page' => $violations->currentPage(),
                'last_page'    => $violations->lastPage(),
                'per_page'     => $violations->perPage(),
                'total'        => $violations->total(),
            ],
        ]);
    }

    /**
     * GET /api/v1/admin/settings
     * Lihat konfigurasi global.
     */
    public function getSettings(): JsonResponse
    {
        $settings = AppSetting::all()->keyBy('setting_key');

        return response()->json([
            'success' => true,
            'data'    => $settings,
        ]);
    }

    /**
     * PUT /api/v1/admin/settings/{setting_key}
     * Ubah setting.
     */
    public function updateSetting(Request $request, string $settingKey): JsonResponse
    {
        $validated = $request->validate([
            'value' => ['required'],
        ]);

        $setting = AppSetting::where('setting_key', $settingKey)->firstOrFail();
        $setting->update(['value' => $validated['value']]);

        return response()->json([
            'success' => true,
            'message' => "Setting '{$settingKey}' berhasil diperbarui",
            'data'    => $setting->fresh(),
        ]);
    }
}
