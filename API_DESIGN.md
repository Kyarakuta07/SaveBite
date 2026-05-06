# API Endpoint Design - SaveBite
**Versi:** 1.0  
**Date:** 6 Mei 2026  
**Base URL:** `http://localhost:8000/api/v1`  
**Auth Method:** Laravel Sanctum (Bearer Token)  
**Format Response:** JSON  

---

## Konvensi Response

### Sukses:
```json
{
  "success": true,
  "message": "Data berhasil diambil",
  "data": { ... }
}
```

### Error:
```json
{
  "success": false,
  "message": "Validasi gagal",
  "errors": {
    "email": ["Email sudah terdaftar"]
  }
}
```

### Pagination:
```json
{
  "success": true,
  "data": [ ... ],
  "meta": {
    "current_page": 1,
    "last_page": 5,
    "per_page": 15,
    "total": 72
  }
}
```

---

## 1. Authentication (User)

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| POST | `/auth/register` | ❌ | Registrasi akun user baru |
| POST | `/auth/login` | ❌ | Login user, return Bearer token |
| POST | `/auth/logout` | 🔒 User | Logout & revoke token |
| GET | `/auth/me` | 🔒 User | Ambil profil user yang sedang login |
| PUT | `/auth/me` | 🔒 User | Update profil (nama, avatar, dll) |
| PUT | `/auth/me/password` | 🔒 User | Ganti password |
| PUT | `/auth/me/fcm-token` | 🔒 User | Update FCM token untuk push notif |

### Request & Response Detail:

**POST `/auth/register`**
```json
// Request
{
  "name": "Budi Santoso",
  "email": "budi@email.com",
  "phone": "081234567890",
  "password": "password123",
  "password_confirmation": "password123"
}

// Response 201
{
  "success": true,
  "message": "Registrasi berhasil",
  "data": {
    "user": { "id": 1, "name": "Budi Santoso", "email": "budi@email.com" },
    "token": "1|abc123tokenxyz..."
  }
}
```

**POST `/auth/login`**
```json
// Request
{
  "email": "budi@email.com",
  "password": "password123"
}

// Response 200
{
  "success": true,
  "data": {
    "user": { "id": 1, "name": "Budi Santoso", "wallet_balance": "50000.00", ... },
    "token": "2|def456tokenxyz..."
  }
}
```

---

## 2. Authentication (Merchant)

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| POST | `/merchant/auth/register` | ❌ | Registrasi akun mitra baru |
| POST | `/merchant/auth/login` | ❌ | Login mitra |
| POST | `/merchant/auth/logout` | 🔒 Merchant | Logout mitra |
| GET | `/merchant/auth/me` | 🔒 Merchant | Profil mitra yang sedang login |
| PUT | `/merchant/auth/me` | 🔒 Merchant | Update profil mitra |
| PUT | `/merchant/auth/me/password` | 🔒 Merchant | Ganti password mitra |
| PUT | `/merchant/auth/me/fcm-token` | 🔒 Merchant | Update FCM token mitra |

**POST `/merchant/auth/register`**
```json
// Request
{
  "name": "Roti Bakar Mantap",
  "display_name": null,
  "is_anonymous": true,
  "category": "bakery",
  "email": "rotibakar@email.com",
  "phone": "081298765432",
  "password": "password123",
  "password_confirmation": "password123",
  "address": "Jl. Sudirman No. 10, Jakarta Pusat",
  "latitude": -6.2088,
  "longitude": 106.8456,
  "operational_hours": {
    "mon": "08:00-22:00",
    "tue": "08:00-22:00"
  }
}
```

---

## 3. Food Items (User — Browse & Search)

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/food-items` | 🔒 User | Daftar makanan available (+ filter & sort) |
| GET | `/food-items/{id}` | 🔒 User | Detail satu makanan |
| GET | `/merchants/{id}` | 🔒 User | Profil publik toko (rating, jam operasi, alamat) |

### Query Parameters untuk `GET /food-items`:
| Param | Type | Contoh | Deskripsi |
|-------|------|--------|-----------|
| `lat` | decimal | `-6.2088` | Latitude user (untuk sorting nearby) |
| `lng` | decimal | `106.8456` | Longitude user |
| `radius` | int | `5` | Radius pencarian dalam KM (default: 10) |
| `category` | string | `bakery` | Filter kategori mitra |
| `search` | string | `croissant` | Cari berdasarkan nama makanan |
| `sort_by` | string | `distance` / `price` / `newest` | Urutan hasil |
| `page` | int | `1` | Halaman pagination |

**Response `GET /food-items`:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "merchant": {
        "id": 5,
        "display_name": "Bakery Anonim",
        "is_anonymous": true,
        "category": "bakery",
        "average_rating": 4.5,
        "total_reviews": 23,
        "distance_km": 1.2
      },
      "name": "Roti Croissant Coklat",
      "image": "https://storage.savebite.id/food/croissant.jpg",
      "original_price": "35000.00",
      "rescue_price": "15000.00",
      "discount_pct": 57,
      "quantity": 5,
      "quantity_sold": 2,
      "reason": "Toko tutup 30 menit lagi",
      "produced_at": "2026-05-06T06:00:00",
      "expires_at": "2026-05-07T00:00:00",
      "status": "available"
    }
  ],
  "meta": { "current_page": 1, "last_page": 3, "total": 42 }
}
```

> ⚠️ **Catatan Anonymous:** Jika `is_anonymous = true`, field `merchant.display_name` diisi nama samaran yang di-generate sistem. `merchant.name` (nama asli) **TIDAK pernah dikirim** ke endpoint user.

---

## 4. Food Items (Merchant — CRUD)

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/merchant/food-items` | 🔒 Merchant | Daftar makanan milik mitra sendiri |
| POST | `/merchant/food-items` | 🔒 Merchant | Upload makanan baru (Quick Upload) |
| PUT | `/merchant/food-items/{id}` | 🔒 Merchant | Edit detail makanan |
| PATCH | `/merchant/food-items/{id}/stock` | 🔒 Merchant | Update stok saja (cepat) |
| DELETE | `/merchant/food-items/{id}` | 🔒 Merchant | Hapus/cancel listing |

**POST `/merchant/food-items`**
```json
// Request (multipart/form-data)
{
  "name": "Roti Croissant Coklat",
  "description": "Roti croissant isi coklat premium",
  "image": "(file upload)",
  "original_price": 35000,
  "rescue_price": 15000,
  "quantity": 5,
  "reason": "Toko tutup 30 menit lagi",
  "produced_at": "2026-05-06T06:00:00",
  "expires_at": "2026-05-07T00:00:00",
  "pickup_only": false
}
// discount_pct dihitung otomatis oleh backend
```

---

## 5. Orders (User)

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| POST | `/orders` | 🔒 User | Buat order baru (checkout) |
| GET | `/orders` | 🔒 User | Riwayat order user |
| GET | `/orders/{id}` | 🔒 User | Detail order + delivery tracking |
| POST | `/orders/{id}/complete` | 🔒 User | Konfirmasi order selesai (manual) |
| POST | `/orders/{id}/cancel` | 🔒 User | Batalkan order (hanya status `confirmed`, sebelum kurir pickup) |

**POST `/orders`**
```json
// Request
{
  "merchant_id": 5,
  "items": [
    { "food_item_id": 1, "quantity": 2 },
    { "food_item_id": 3, "quantity": 1 }
  ],
  "payment_method": "qris",
  "delivery_address": "Jl. Gatot Subroto No. 15, Jakarta",
  "delivery_lat": -6.2350,
  "delivery_lng": 106.8200,
  "notes": "Lantai 3, pintu kiri"
}

// Response 201
{
  "success": true,
  "message": "Order berhasil dibuat",
  "data": {
    "order": {
      "id": 101,
      "order_code": "SB-20260506-0001",
      "subtotal": "50000.00",
      "delivery_fee": "12000.00",
      "commission_fee": "2500.00",
      "total_amount": "62000.00",
      "savings_amount": "55000.00",
      "payment_method": "qris",
      "payment_status": "pending",
      "order_status": "pending"
    },
    "payment": {
      "payment_url": "https://app.midtrans.com/snap/v2/qris/...",
      "payment_type": "qris",
      "expires_at": "2026-05-06T21:15:00"
    }
  }
}
```

> ℹ️ **Alur setelah POST `/orders`:**
>
> **Jika bayar via QRIS / E-Wallet / Transfer Bank:**
> 1. Response berisi `payment_url` → Frontend redirect atau tampilkan QR
> 2. User bayar → webhook dari Midtrans masuk ke backend
> 3. Backend auto-confirm → panggil API kurir → notif ke mitra
>
> **Jika bayar via Wallet:**
> 1. Saldo langsung dipotong → `payment_status` = `paid`, `order_status` = `confirmed`
> 2. Response **tidak ada** `payment` object (tidak perlu redirect)
> 3. Backend langsung panggil API kurir → notif ke mitra

---

## 6. Orders (Merchant)

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/merchant/orders` | 🔒 Merchant | Daftar order masuk untuk mitra |
| GET | `/merchant/orders/{id}` | 🔒 Merchant | Detail order |

> ℹ️ Mitra tidak perlu endpoint "terima order" karena auto-confirm.

---

## 7. Deliveries & Tracking

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/orders/{id}/delivery` | 🔒 User | Status delivery + info driver + live tracking URL |
| POST | `/orders/{id}/self-pickup` | 🔒 User | User pilih self-pickup (jika kurir gagal) |

**Response `GET /orders/{id}/delivery`:**
```json
{
  "success": true,
  "data": {
    "provider": "grab",
    "tracking_id": "GRB-123456",
    "status": "on_the_way",
    "driver": {
      "name": "Andi",
      "phone": "081299998888",
      "vehicle": "Honda Beat - B 1234 XYZ"
    },
    "live_tracking_url": "https://grab.com/track/GRB-123456",
    "estimated_arrival": "2026-05-06T20:55:00"
  }
}
```

---

## 8. Webhooks (Dari Pihak Ketiga → SaveBite)

> ⚠️ Endpoint ini **bukan** untuk Flutter. Ini dipanggil otomatis oleh server Midtrans/kurir.

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| POST | `/webhooks/midtrans` | Signature | Callback status pembayaran dari Midtrans |
| POST | `/webhooks/delivery` | API Key | Callback status pengiriman dari kurir API |

**POST `/webhooks/midtrans`** (contoh payload masuk):
```json
{
  "order_id": "SB-20260506-0001",
  "transaction_status": "settlement",
  "payment_type": "qris",
  "gross_amount": "62000.00",
  "signature_key": "abc123..."
}
// Backend: verify signature → update payment_status='paid' → auto-confirm → dispatch kurir
```

---

## 9. Reviews

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| POST | `/orders/{id}/review` | 🔒 User | Buat review untuk order yang completed |
| GET | `/merchants/{id}/reviews` | 🔒 User | Lihat semua review sebuah toko |
| POST | `/merchant/reviews/{id}/reply` | 🔒 Merchant | Mitra balas review |

**POST `/orders/{id}/review`**
```json
// Request
{
  "rating": 5,
  "comment": "Makanannya masih segar, harga super murah!",
  "is_anonymous": false
}
```

---

## 10. Disputes

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| POST | `/orders/{id}/dispute` | 🔒 User | Ajukan komplain (max 60 menit) |
| GET | `/disputes/{id}` | 🔒 User | Lihat status komplain |

**POST `/orders/{id}/dispute`**
```json
// Request (multipart/form-data)
{
  "reason": "Roti sudah berjamur dan bau tengik",
  "photo_proof": "(file upload - WAJIB)",
  "video_proof": "(file upload - WAJIB)"
}

// Response 201
{
  "success": true,
  "message": "Komplain berhasil diajukan, tim kami akan meninjau dalam 1x24 jam",
  "data": {
    "dispute_id": 15,
    "status": "pending"
  }
}
```

---

## 11. Follow & Notifications

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| POST | `/merchants/{id}/follow` | 🔒 User | Follow toko |
| DELETE | `/merchants/{id}/follow` | 🔒 User | Unfollow toko |
| GET | `/me/follows` | 🔒 User | Daftar toko yang di-follow |
| GET | `/me/notifications` | 🔒 User | Riwayat notifikasi |
| POST | `/me/notifications/read-all` | 🔒 User | Tandai semua notifikasi sudah dibaca |

---

## 12. Wallet

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/me/wallet` | 🔒 User | Saldo wallet + ringkasan |
| POST | `/me/wallet/topup` | 🔒 User | Request top-up (return payment URL) |
| GET | `/me/wallet/transactions` | 🔒 User | Riwayat mutasi saldo |
| GET | `/merchant/wallet` | 🔒 Merchant | Saldo wallet mitra |
| GET | `/merchant/wallet/transactions` | 🔒 Merchant | Riwayat mutasi mitra |
| POST | `/merchant/wallet/withdraw` | 🔒 Merchant | Request penarikan saldo |

**POST `/me/wallet/topup`**
```json
// Request
{
  "amount": 100000,
  "payment_method": "qris"
}

// Response 200
{
  "success": true,
  "data": {
    "payment_url": "https://app.midtrans.com/snap/v2/qris/...",
    "expires_at": "2026-05-06T21:30:00"
  }
}
```

---

## 13. Admin Panel

> ℹ️ Endpoint admin bisa diakses via web dashboard (Laravel Blade/Inertia) atau API terpisah.

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| POST | `/admin/auth/login` | ❌ | Login admin |
| GET | `/admin/dashboard` | 🔒 Admin | Statistik: total order, revenue, user aktif |
| GET | `/admin/disputes` | 🔒 Admin | Daftar semua komplain pending |
| PUT | `/admin/disputes/{id}` | 🔒 Admin | Approve/reject dispute + refund |
| GET | `/admin/merchants` | 🔒 Admin | Daftar semua mitra |
| PUT | `/admin/merchants/{id}/verify` | 🔒 Admin | Verifikasi mitra baru |
| PUT | `/admin/merchants/{id}/suspend` | 🔒 Admin | Skors mitra manual |
| GET | `/admin/violations` | 🔒 Admin | Riwayat pelanggaran semua mitra |
| GET | `/admin/settings` | 🔒 Admin | Lihat konfigurasi global |
| PUT | `/admin/settings/{setting_key}` | 🔒 Admin | Ubah setting (misal: commission_rate) |

**PUT `/admin/disputes/{id}`**
```json
// Request
{
  "status": "approved",
  "admin_notes": "Bukti valid, makanan memang berjamur. Refund 100%.",
  "refund_amount": 50000
}
// Backend: refund ke wallet user + tambah violation mitra + notif kedua pihak
```

---

## Ringkasan Jumlah Endpoint

| Modul | Jumlah | Guard |
|-------|--------|-------|
| Auth User | 7 | Public + User |
| Auth Merchant | 7 | Public + Merchant |
| Food Items (User) | 3 | User |
| Food Items (Merchant) | 5 | Merchant |
| Orders (User) | 5 | User |
| Orders (Merchant) | 2 | Merchant |
| Deliveries | 2 | User |
| Webhooks | 2 | Signature/API Key |
| Reviews | 3 | User + Merchant |
| Disputes | 2 | User |
| Follow & Notifications | 5 | User |
| Wallet | 6 | User + Merchant |
| Admin | 10 | Admin |
| **TOTAL** | **59 endpoint** | |

---

## Catatan Implementasi Laravel

### Guard (Middleware):
```
🔒 User      → auth:sanctum + middleware('role:user')
🔒 Merchant  → auth:sanctum + middleware('role:merchant')
🔒 Admin     → auth:sanctum + middleware('role:admin')
```

### Route Grouping:
```php
Route::prefix('v1')->group(function () {
    // === PUBLIC (tanpa auth) ===
    Route::post('auth/register', ...);
    Route::post('auth/login', ...);
    Route::prefix('merchant/auth')->group(function () {
        Route::post('register', ...);
        Route::post('login', ...);
    });
    Route::post('admin/auth/login', ...);
    
    // === USER (auth required) ===
    Route::middleware('auth:sanctum', 'role:user')->group(function () {
        Route::get('food-items', ...);
        Route::post('orders', ...);
        // ...
    });
    
    // === MERCHANT (auth required) ===
    Route::prefix('merchant')->middleware('auth:sanctum', 'role:merchant')->group(function () {
        Route::get('food-items', ...);
        Route::post('food-items', ...);
        // ...
    });
    
    // === ADMIN (auth required) ===
    Route::prefix('admin')->middleware('auth:sanctum', 'role:admin')->group(function () {
        Route::get('dashboard', ...);
        // ...
    });
    
    // === WEBHOOKS (no auth, verified by signature) ===
    Route::prefix('webhooks')->group(function () {
        Route::post('midtrans', ...);
        Route::post('delivery', ...);
    });
});
```
