<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Http\Controllers\Controller;
use App\Models\Merchant;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class MerchantAuthController extends Controller
{
    // POST /api/v1/merchant/auth/register
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name'              => ['required', 'string', 'max:100'],
            'display_name'      => ['nullable', 'string', 'max:100'],
            'is_anonymous'      => ['sometimes', 'boolean'],
            'category'          => ['required', 'in:fast_food,bakery,supermarket'],
            'email'             => ['required', 'email', 'unique:merchants,email'],
            'phone'             => ['required', 'string', 'max:20', 'unique:merchants,phone'],
            'password'          => ['required', 'confirmed', Password::min(8)],
            'address'           => ['required', 'string'],
            'latitude'          => ['required', 'numeric', 'between:-90,90'],
            'longitude'         => ['required', 'numeric', 'between:-180,180'],
            'operational_hours' => ['sometimes', 'array'],
        ]);

        $isAnonymous = $validated['is_anonymous'] ?? false;

        $merchant = Merchant::create([
            'name'              => $validated['name'],
            'display_name'      => $validated['display_name'] ?? null,
            'is_anonymous'      => $isAnonymous,
            'category'          => $validated['category'],
            'email'             => $validated['email'],
            'phone'             => $validated['phone'],
            'password'          => Hash::make($validated['password']),
            'address'           => $validated['address'],
            'latitude'          => $validated['latitude'],
            'longitude'         => $validated['longitude'],
            'operational_hours' => $validated['operational_hours'] ?? null,
            'status'            => 'active',   // eksplisit set agar PHP model tidak null
            'is_verified'       => false,       // eksplisit set agar PHP model tidak null
        ]);

        // fresh() memastikan semua nilai diambil ulang dari database
        $merchant = $merchant->fresh();

        $token = $merchant->createToken('merchant-token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Registrasi mitra berhasil. Menunggu verifikasi admin.',
            'data'    => [
                'merchant' => [
                    'id'          => $merchant->id,
                    'name'        => $merchant->name,
                    'display_name'=> $merchant->display_name,
                    'category'    => $merchant->category,
                    'status'      => $merchant->status,       // 'active'
                    'is_verified' => $merchant->is_verified,  // false
                    'keterangan'  => 'Menunggu verifikasi admin',
                ],
                'token' => $token,
            ],
        ], 201);
    }

    // POST /api/v1/merchant/auth/login
    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email'    => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $merchant = Merchant::where('email', $validated['email'])->first();

        if (! $merchant || ! Hash::check($validated['password'], $merchant->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Email atau password salah.',
            ], 401);
        }

        if ($merchant->status === 'banned') {
            return response()->json([
                'success' => false,
                'message' => 'Akun Anda telah dibanned secara permanen.',
            ], 403);
        }

        $merchant->tokens()->delete();
        $token = $merchant->createToken('merchant-token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login berhasil',
            'data'    => [
                'merchant' => $merchant->only([
                    'id', 'name', 'display_name', 'is_anonymous', 'category',
                    'status', 'wallet_balance', 'average_rating',
                ]),
                'token' => $token,
            ],
        ]);
    }

    // POST /api/v1/merchant/auth/logout
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logout berhasil',
        ]);
    }

    // GET /api/v1/merchant/auth/me
    public function me(Request $request): JsonResponse
    {
        $merchant = $request->user();

        // Never expose real name if anonymous
        $data = $merchant->toArray();
        if ($merchant->is_anonymous) {
            unset($data['name']);
        }

        return response()->json([
            'success' => true,
            'data'    => $data,
        ]);
    }

    // PUT /api/v1/merchant/auth/me
    public function updateProfile(Request $request): JsonResponse
    {
        $merchant  = $request->user();
        $validated = $request->validate([
            'display_name'      => ['sometimes', 'nullable', 'string', 'max:100'],
            'phone'             => ['sometimes', 'string', 'max:20', 'unique:merchants,phone,' . $merchant->id],
            'address'           => ['sometimes', 'string'],
            'latitude'          => ['sometimes', 'numeric', 'between:-90,90'],
            'longitude'         => ['sometimes', 'numeric', 'between:-180,180'],
            'operational_hours' => ['sometimes', 'array'],
            'logo'              => ['sometimes', 'image', 'max:2048'],
        ]);

        if ($request->hasFile('logo')) {
            $path = $request->file('logo')->store('logos', 'public');
            $validated['logo'] = $path;
        }

        $merchant->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Profil mitra berhasil diperbarui',
            'data'    => $merchant->fresh(),
        ]);
    }

    // PUT /api/v1/merchant/auth/me/password
    public function updatePassword(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'current_password' => ['required', 'string'],
            'password'         => ['required', 'confirmed', Password::min(8)],
        ]);

        $merchant = $request->user();

        if (! Hash::check($validated['current_password'], $merchant->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Password lama tidak sesuai.',
            ], 422);
        }

        $merchant->update(['password' => Hash::make($validated['password'])]);
        $merchant->tokens()->delete();
        $token = $merchant->createToken('merchant-token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Password berhasil diperbarui',
            'data'    => ['token' => $token],
        ]);
    }

    // PUT /api/v1/merchant/auth/me/fcm-token
    public function updateFcmToken(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'fcm_token' => ['required', 'string'],
        ]);

        $request->user()->update(['fcm_token' => $validated['fcm_token']]);

        return response()->json([
            'success' => true,
            'message' => 'FCM token berhasil diperbarui',
        ]);
    }
}
