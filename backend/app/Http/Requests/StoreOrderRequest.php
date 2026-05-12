<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Validates order creation (checkout) requests.
 *
 * Extracts validation rules from OrderController::store() to a dedicated class.
 * Provides clear Indonesian error messages for the Flutter client.
 */
class StoreOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Auth handled by Sanctum + role middleware
    }

    public function rules(): array
    {
        return [
            'merchant_id'          => ['required', 'integer', 'exists:merchants,id'],
            'items'                => ['required', 'array', 'min:1'],
            'items.*.food_item_id' => ['required', 'integer', 'exists:food_items,id'],
            'items.*.quantity'     => ['required', 'integer', 'min:1'],
            'payment_method'      => ['required', 'in:wallet,qris,e_wallet,bank_transfer'],
            'delivery_address'    => ['required_if:payment_method,qris,e_wallet,bank_transfer', 'nullable', 'string'],
            'delivery_lat'        => ['nullable', 'numeric'],
            'delivery_lng'        => ['nullable', 'numeric'],
            'notes'               => ['nullable', 'string', 'max:500'],
        ];
    }

    public function messages(): array
    {
        return [
            'merchant_id.required'          => 'Merchant ID wajib diisi.',
            'merchant_id.exists'            => 'Merchant tidak ditemukan.',
            'items.required'                => 'Minimal 1 item harus dipesan.',
            'items.min'                     => 'Minimal 1 item harus dipesan.',
            'items.*.food_item_id.required' => 'ID item makanan wajib diisi.',
            'items.*.food_item_id.exists'   => 'Item makanan tidak ditemukan.',
            'items.*.quantity.min'          => 'Jumlah minimal 1.',
            'payment_method.required'       => 'Metode pembayaran wajib dipilih.',
            'payment_method.in'             => 'Metode pembayaran tidak valid.',
            'delivery_address.required_if'  => 'Alamat pengiriman wajib diisi untuk pembayaran non-wallet.',
            'notes.max'                     => 'Catatan maksimal 500 karakter.',
        ];
    }
}
