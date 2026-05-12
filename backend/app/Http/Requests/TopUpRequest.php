<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Validates wallet top-up requests.
 *
 * Extracted from WalletController::topup() for consistency and testability.
 */
class TopUpRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Auth handled by Sanctum + role middleware
    }

    public function rules(): array
    {
        return [
            'amount'         => ['required', 'integer', 'min:10000', 'max:10000000'],
            'payment_method' => ['required', 'in:qris,e_wallet,bank_transfer'],
        ];
    }

    public function messages(): array
    {
        return [
            'amount.required'         => 'Jumlah top-up wajib diisi.',
            'amount.integer'          => 'Jumlah top-up harus berupa angka bulat.',
            'amount.min'              => 'Minimal top-up Rp 10.000.',
            'amount.max'              => 'Maksimal top-up Rp 10.000.000.',
            'payment_method.required' => 'Metode pembayaran wajib dipilih.',
            'payment_method.in'       => 'Metode pembayaran tidak valid.',
        ];
    }
}
