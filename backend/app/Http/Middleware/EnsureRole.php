<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureRole
{
    public function handle(Request $request, Closure $next, string $role): Response
    {
        $user = $request->user();

        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Unauthenticated.'], 401);
        }

        $allowed = match ($role) {
            'user'     => $user instanceof \App\Models\User,
            'merchant' => $user instanceof \App\Models\Merchant,
            'admin'    => $user instanceof \App\Models\Admin,
            default    => false,
        };

        if (! $allowed) {
            return response()->json(['success' => false, 'message' => 'Akses ditolak.'], 403);
        }

        return $next($request);
    }
}
