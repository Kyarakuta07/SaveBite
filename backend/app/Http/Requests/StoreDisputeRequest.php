<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Validates dispute submission requests.
 *
 * Extracted from DisputeController::store() for consistency.
 * Field names match the existing controller: photo_proof, video_proof.
 * Enforces the 20-character minimum that Flutter already validates client-side.
 */
class StoreDisputeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Auth handled by Sanctum + role middleware
    }

    public function rules(): array
    {
        return [
            'reason'      => ['required', 'string', 'min:20', 'max:1000'],
            'photo_proof' => ['required', 'image', 'max:10240'],   // 10MB max (matches existing)
            'video_proof' => ['required', 'mimes:mp4,mov,avi', 'max:51200'],  // 50MB max
        ];
    }

    public function messages(): array
    {
        return [
            'reason.required'      => 'Alasan komplain wajib diisi.',
            'reason.min'           => 'Alasan minimal 20 karakter.',
            'reason.max'           => 'Alasan maksimal 1.000 karakter.',
            'photo_proof.required' => 'Foto bukti wajib dilampirkan.',
            'photo_proof.image'    => 'File harus berupa gambar (jpg, png, gif).',
            'photo_proof.max'      => 'Ukuran foto maksimal 10MB.',
            'video_proof.required' => 'Video bukti wajib dilampirkan.',
            'video_proof.mimes'    => 'Video harus format MP4, MOV, atau AVI.',
            'video_proof.max'      => 'Ukuran video maksimal 50MB.',
        ];
    }
}
