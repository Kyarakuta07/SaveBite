<?php

use App\Http\Controllers\Api\V1\Admin\AdminController;
use App\Http\Controllers\Api\V1\Auth\AdminAuthController;
use App\Http\Controllers\Api\V1\Auth\MerchantAuthController;
use App\Http\Controllers\Api\V1\Auth\UserAuthController;
use App\Http\Controllers\Api\V1\DeliveryController;
use App\Http\Controllers\Api\V1\DisputeController;
use App\Http\Controllers\Api\V1\FoodItemController;
use App\Http\Controllers\Api\V1\Merchant\MerchantFoodItemController;
use App\Http\Controllers\Api\V1\Merchant\MerchantOrderController;
use App\Http\Controllers\Api\V1\Merchant\MerchantReviewController;
use App\Http\Controllers\Api\V1\OrderController;
use App\Http\Controllers\Api\V1\ReviewController;
use App\Http\Controllers\Api\V1\SocialController;
use App\Http\Controllers\Api\V1\UserAddressController;
use App\Http\Controllers\Api\V1\WalletController;
use App\Http\Controllers\Api\V1\WebhookController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| SaveBite API Routes — Base URL: /api/v1
|--------------------------------------------------------------------------
| Auth:  Laravel Sanctum (Bearer Token)
| Guards: role:user | role:merchant | role:admin
*/

Route::prefix('v1')->group(function () {

    // ─────────────────────────────────────────────────────────────────────
    // PUBLIC ROUTES (No authentication required)
    // ─────────────────────────────────────────────────────────────────────

    // 1. Auth User (Public)
    Route::prefix('auth')->group(function () {
        Route::post('register', [UserAuthController::class, 'register']);
        Route::post('login',    [UserAuthController::class, 'login']);
    });

    // 2. Auth Merchant (Public)
    Route::prefix('merchant/auth')->group(function () {
        Route::post('register', [MerchantAuthController::class, 'register']);
        Route::post('login',    [MerchantAuthController::class, 'login']);
    });

    // 3. Auth Admin (Public)
    Route::post('admin/auth/login', [AdminAuthController::class, 'login']);

    // 8. Webhooks (no auth, verified by signature/api-key)
    Route::prefix('webhooks')->group(function () {
        Route::post('midtrans', [WebhookController::class, 'midtrans']);
        Route::post('delivery', [WebhookController::class, 'delivery']);
    });

    // ─────────────────────────────────────────────────────────────────────
    // USER ROUTES (auth:sanctum + role:user)
    // ─────────────────────────────────────────────────────────────────────
    Route::middleware(['auth:sanctum', 'role:user'])->group(function () {

        // 1. Auth User (Protected)
        Route::prefix('auth')->group(function () {
            Route::post('logout',           [UserAuthController::class, 'logout']);
            Route::get('me',                [UserAuthController::class, 'me']);
            Route::put('me',                [UserAuthController::class, 'updateProfile']);
            Route::put('me/password',       [UserAuthController::class, 'updatePassword']);
            Route::put('me/fcm-token',      [UserAuthController::class, 'updateFcmToken']);
        });

        // 3. Food Items (User — Browse & Search)
        Route::get('food-items',           [FoodItemController::class, 'index']);
        Route::get('food-items/flash-sale', [FoodItemController::class, 'flashSale']);
        Route::get('food-items/{id}',      [FoodItemController::class, 'show']);
        Route::get('merchants/{id}',       [FoodItemController::class, 'merchantProfile']);

        // 5. Orders (User)
        Route::get('orders',                    [OrderController::class, 'index']);
        Route::post('orders',                   [OrderController::class, 'store']);
        Route::get('orders/{id}',               [OrderController::class, 'show']);
        Route::post('orders/{id}/complete',     [OrderController::class, 'complete']);
        Route::post('orders/{id}/cancel',       [OrderController::class, 'cancel']);
        Route::post('orders/{id}/reorder',      [OrderController::class, 'reorder']);

        // 7. Deliveries & Tracking
        Route::get('orders/{id}/delivery',   [DeliveryController::class, 'show']);
        Route::post('orders/{id}/self-pickup',[DeliveryController::class, 'selfPickup']);

        // 9. Reviews (User)
        Route::post('orders/{id}/review',    [ReviewController::class, 'store']);
        Route::get('merchants/{id}/reviews', [ReviewController::class, 'merchantReviews']);

        // 10. Disputes
        Route::post('orders/{id}/dispute',   [DisputeController::class, 'store']);
        Route::get('disputes/{id}',          [DisputeController::class, 'show']);

        // 11. Follow & Notifications
        Route::post('merchants/{id}/follow',         [SocialController::class, 'follow']);
        Route::delete('merchants/{id}/follow',       [SocialController::class, 'unfollow']);
        Route::get('me/follows',                     [SocialController::class, 'myFollows']);
        Route::get('me/notifications',               [SocialController::class, 'notifications']);
        Route::post('me/notifications/read-all',     [SocialController::class, 'readAllNotifications']);

        // 12. Wallet (User)
        Route::get('me/wallet',                      [WalletController::class, 'userWallet']);
        Route::post('me/wallet/topup',               [WalletController::class, 'topup']);
        Route::get('me/wallet/transactions',         [WalletController::class, 'userTransactions']);

        // 13. Saved Addresses (User)
        Route::get('me/addresses',                   [UserAddressController::class, 'index']);
        Route::post('me/addresses',                  [UserAddressController::class, 'store']);
        Route::put('me/addresses/{id}',              [UserAddressController::class, 'update']);
        Route::patch('me/addresses/{id}/default',    [UserAddressController::class, 'setDefault']);
        Route::delete('me/addresses/{id}',           [UserAddressController::class, 'destroy']);
    });

    // ─────────────────────────────────────────────────────────────────────
    // MERCHANT ROUTES (auth:sanctum + role:merchant)
    // ─────────────────────────────────────────────────────────────────────
    Route::prefix('merchant')->middleware(['auth:sanctum', 'role:merchant'])->group(function () {

        // 2. Auth Merchant (Protected)
        Route::prefix('auth')->group(function () {
            Route::post('logout',       [MerchantAuthController::class, 'logout']);
            Route::get('me',            [MerchantAuthController::class, 'me']);
            Route::put('me',            [MerchantAuthController::class, 'updateProfile']);
            Route::put('me/password',   [MerchantAuthController::class, 'updatePassword']);
            Route::put('me/fcm-token',  [MerchantAuthController::class, 'updateFcmToken']);
        });

        // 4. Food Items (Merchant — CRUD)
        Route::get('food-items',                           [MerchantFoodItemController::class, 'index']);
        Route::post('food-items',                          [MerchantFoodItemController::class, 'store']);
        Route::put('food-items/{id}',                      [MerchantFoodItemController::class, 'update']);
        Route::patch('food-items/{id}/stock',              [MerchantFoodItemController::class, 'updateStock']);
        Route::delete('food-items/{id}',                   [MerchantFoodItemController::class, 'destroy']);

        // 6. Orders (Merchant)
        Route::get('orders',                               [MerchantOrderController::class, 'index']);
        Route::get('orders/{id}',                          [MerchantOrderController::class, 'show']);

        // 9. Reviews (Merchant — Reply)
        Route::post('reviews/{id}/reply',                  [MerchantReviewController::class, 'reply']);

        // 12. Wallet (Merchant)
        Route::get('wallet',                               [WalletController::class, 'merchantWallet']);
        Route::get('wallet/transactions',                  [WalletController::class, 'merchantTransactions']);
        Route::post('wallet/withdraw',                     [WalletController::class, 'withdraw']);
    });

    // ─────────────────────────────────────────────────────────────────────
    // ADMIN ROUTES (auth:sanctum + role:admin)
    // ─────────────────────────────────────────────────────────────────────
    Route::prefix('admin')->middleware(['auth:sanctum', 'role:admin'])->group(function () {

        // 13. Admin Panel
        Route::get('dashboard',                     [AdminController::class, 'dashboard']);
        Route::get('disputes',                      [AdminController::class, 'disputes']);
        Route::put('disputes/{id}',                 [AdminController::class, 'resolveDispute']);
        Route::get('merchants',                     [AdminController::class, 'merchants']);
        Route::put('merchants/{id}/verify',         [AdminController::class, 'verifyMerchant']);
        Route::put('merchants/{id}/suspend',        [AdminController::class, 'suspendMerchant']);
        Route::get('violations',                    [AdminController::class, 'violations']);
        Route::get('settings',                      [AdminController::class, 'getSettings']);
        Route::put('settings/{setting_key}',        [AdminController::class, 'updateSetting']);
    });
});
