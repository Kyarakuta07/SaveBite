<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\UserAddress;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class UserAddressController extends Controller
{
    /**
     * GET /me/addresses
     * Daftar semua alamat tersimpan milik user.
     */
    public function index(Request $request)
    {
        $addresses = $request->user()->addresses()->get();

        return response()->json([
            'success' => true,
            'data'    => $addresses,
        ]);
    }

    /**
     * POST /me/addresses
     * Tambah alamat baru.
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'label'          => 'required|string|max:50',
            'recipient_name' => 'required|string|max:100',
            'phone'          => 'required|string|max:20',
            'address'        => 'required|string',
            'detail'         => 'nullable|string|max:200',
            'latitude'       => 'nullable|numeric|between:-90,90',
            'longitude'      => 'nullable|numeric|between:-180,180',
            'is_default'     => 'boolean',
        ]);

        $user = $request->user();
        $createdAddress = null;

        DB::transaction(function () use ($user, $data, &$createdAddress) {
            // Jika set sebagai default, lepas default dari alamat lain
            if (!empty($data['is_default'])) {
                $user->addresses()->update(['is_default' => false]);
            }

            // Jika ini alamat pertama, jadikan default otomatis
            if ($user->addresses()->count() === 0) {
                $data['is_default'] = true;
            }

            $createdAddress = $user->addresses()->create($data);
        });

        return response()->json([
            'success' => true,
            'message' => 'Alamat berhasil ditambahkan.',
            'data'    => $createdAddress,
        ], 201);
    }

    /**
     * PUT /me/addresses/{id}
     * Update alamat.
     */
    public function update(Request $request, int $id)
    {
        $address = $request->user()->addresses()->findOrFail($id);

        $data = $request->validate([
            'label'          => 'sometimes|string|max:50',
            'recipient_name' => 'sometimes|string|max:100',
            'phone'          => 'sometimes|string|max:20',
            'address'        => 'sometimes|string',
            'detail'         => 'nullable|string|max:200',
            'latitude'       => 'nullable|numeric|between:-90,90',
            'longitude'      => 'nullable|numeric|between:-180,180',
        ]);

        $address->update($data);

        return response()->json([
            'success' => true,
            'message' => 'Alamat berhasil diperbarui.',
            'data'    => $address->fresh(),
        ]);
    }

    /**
     * PATCH /me/addresses/{id}/default
     * Jadikan alamat ini sebagai default.
     */
    public function setDefault(Request $request, int $id)
    {
        $user = $request->user();
        $address = $user->addresses()->findOrFail($id);

        DB::transaction(function () use ($user, $address) {
            $user->addresses()->update(['is_default' => false]);
            $address->update(['is_default' => true]);
        });

        return response()->json([
            'success' => true,
            'message' => "Alamat '{$address->label}' dijadikan alamat utama.",
            'data'    => $address->fresh(),
        ]);
    }

    /**
     * DELETE /me/addresses/{id}
     * Hapus alamat. Jika yang dihapus adalah default, promote alamat berikutnya.
     */
    public function destroy(Request $request, int $id)
    {
        $user    = $request->user();
        $address = $user->addresses()->findOrFail($id);
        $wasDefault = $address->is_default;

        DB::transaction(function () use ($user, $address, $wasDefault) {
            $address->delete();

            // Promote alamat pertama sebagai default jika yang dihapus adalah default
            if ($wasDefault) {
                $user->addresses()->first()?->update(['is_default' => true]);
            }
        });

        return response()->json([
            'success' => true,
            'message' => 'Alamat berhasil dihapus.',
        ]);
    }
}
