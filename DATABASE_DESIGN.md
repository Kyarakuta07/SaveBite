# Database Design - SaveBite
**Versi:** 1.2  
**Date:** 6 Mei 2026  
**Database:** MySQL  
**Changelog v1.1:** Tambah `order_items` (multi-item order), `reviews` (rating mitra), logika komisi di `wallet_transactions`.  
**Changelog v1.2:** Tambah tabel `admins`, `app_settings`, kolom agregat rating di `merchants`.  
**Changelog v1.3:** Fix seed data `setting_key`, lengkapi ringkasan relasi `admins`, tambah catatan urutan migrasi.

---

## Diagram Relasi (ERD Overview)

```
users ──────────── orders ──────────── order_items ──── food_items
  │                  │                                       │
  │                  │                                       │
  ├── user_follows  deliveries                           merchants
  │                  │                                       │
  ├── reviews       disputes ──── merchant_violations ───────┘
  │                                       │
  └── notifications                    admins ──── app_settings

users/merchants/platform ──── wallet_transactions
```

---

## 1. Tabel `users` (Data Pengguna/Konsumen)

```sql
CREATE TABLE users (
    id              BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    name            VARCHAR(100)    NOT NULL,
    email           VARCHAR(150)    UNIQUE NOT NULL,
    phone           VARCHAR(20)     UNIQUE NOT NULL,
    password        VARCHAR(255)    NOT NULL,
    avatar          VARCHAR(255)    NULL,
    wallet_balance  DECIMAL(12, 2)  NOT NULL DEFAULT 0.00,
    point_balance   INT UNSIGNED    NOT NULL DEFAULT 0,
    total_saved     DECIMAL(12, 2)  NOT NULL DEFAULT 0.00,  -- Total uang dihemat (Rp)
    total_rescued   INT UNSIGNED    NOT NULL DEFAULT 0,     -- Total porsi diselamatkan
    fcm_token       VARCHAR(255)    NULL,                   -- Token untuk Push Notification
    is_active       TINYINT(1)      NOT NULL DEFAULT 1,
    email_verified_at TIMESTAMP     NULL,
    created_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

---

## 2. Tabel `merchants` (Data Mitra/Toko)

```sql
CREATE TABLE merchants (
    id              BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    name            VARCHAR(150)    NOT NULL,                 -- Nama asli toko
    display_name    VARCHAR(150)    NULL,                     -- Nama publik (jika anonymous, NULL)
    is_anonymous    TINYINT(1)      NOT NULL DEFAULT 0,       -- 1 = Sembunyikan nama brand
    category        ENUM('fast_food', 'bakery', 'supermarket') NOT NULL,
    email           VARCHAR(150)    UNIQUE NOT NULL,
    phone           VARCHAR(20)     NOT NULL,
    password        VARCHAR(255)    NOT NULL,
    logo            VARCHAR(255)    NULL,
    address         TEXT            NOT NULL,
    latitude        DECIMAL(10, 8)  NOT NULL,
    longitude       DECIMAL(11, 8)  NOT NULL,
    operational_hours JSON          NULL,                     -- {"mon": "08:00-22:00", ...}
    wallet_balance  DECIMAL(12, 2)  NOT NULL DEFAULT 0.00,
    average_rating  DECIMAL(3, 2)   NOT NULL DEFAULT 0.00,    -- Rata-rata bintang (di-update tiap ada review baru)
    total_reviews   INT UNSIGNED    NOT NULL DEFAULT 0,       -- Jumlah ulasan masuk
    status          ENUM('active', 'suspended', 'banned') NOT NULL DEFAULT 'active',
    suspension_until DATE           NULL,                     -- Tanggal berakhirnya masa skors
    violation_count TINYINT         NOT NULL DEFAULT 0,
    fcm_token       VARCHAR(255)    NULL,
    is_verified     TINYINT(1)      NOT NULL DEFAULT 0,       -- Verifikasi oleh admin SaveBite
    created_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

---

## 3. Tabel `food_items` (Daftar Makanan yang Dijual)

```sql
CREATE TABLE food_items (
    id              BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    merchant_id     BIGINT UNSIGNED NOT NULL,
    name            VARCHAR(200)    NOT NULL,
    description     TEXT            NULL,
    image           VARCHAR(255)    NULL,
    original_price  DECIMAL(10, 2)  NOT NULL,                 -- Harga normal
    rescue_price    DECIMAL(10, 2)  NOT NULL,                 -- Harga SaveBite (harga diskon)
    discount_pct    TINYINT UNSIGNED NOT NULL,                 -- Persentase diskon (%)
    quantity        SMALLINT UNSIGNED NOT NULL DEFAULT 1,      -- Stok yang tersedia
    quantity_sold   SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    reason          VARCHAR(255)    NOT NULL,                  -- "Toko mau tutup", "Stok berlebih", dll
    produced_at     DATETIME        NULL,                      -- Waktu produksi makanan
    expires_at      DATETIME        NULL,                      -- Waktu kedaluwarsa
    status          ENUM('available', 'sold_out', 'expired', 'cancelled') NOT NULL DEFAULT 'available',
    pickup_only     TINYINT(1)      NOT NULL DEFAULT 0,        -- 1 = Hanya ambil sendiri (tanpa kurir)
    created_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (merchant_id) REFERENCES merchants(id) ON DELETE CASCADE,
    INDEX idx_status (status),
    INDEX idx_merchant_status (merchant_id, status)
);
```

---

## 4. Tabel `orders` (Header Transaksi)

> ℹ️ Satu `order` bisa berisi **banyak item makanan** dari merchant yang sama.
> Detail item disimpan di tabel `order_items`.

```sql
CREATE TABLE orders (
    id              BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    order_code      VARCHAR(20)     UNIQUE NOT NULL,           -- Kode unik: SB-20260506-XXXX
    user_id         BIGINT UNSIGNED NOT NULL,
    merchant_id     BIGINT UNSIGNED NOT NULL,
    subtotal        DECIMAL(12, 2)  NOT NULL,                  -- Total harga semua item
    delivery_fee    DECIMAL(10, 2)  NOT NULL DEFAULT 0.00,
    commission_fee  DECIMAL(10, 2)  NOT NULL DEFAULT 0.00,     -- Komisi SaveBite (dipotong dari merchant)
    total_amount    DECIMAL(12, 2)  NOT NULL,                  -- Grand total dibayar user
    savings_amount  DECIMAL(12, 2)  NOT NULL DEFAULT 0.00,     -- Total penghematan user (vs harga normal)
    payment_method  ENUM('wallet', 'qris', 'e_wallet', 'bank_transfer') NOT NULL,
    payment_status  ENUM('pending', 'paid', 'failed', 'refunded') NOT NULL DEFAULT 'pending',
    order_status    ENUM('pending', 'confirmed', 'picked_up', 'delivered', 'completed', 'cancelled') NOT NULL DEFAULT 'pending',
    delivery_address TEXT           NULL,
    delivery_lat    DECIMAL(10, 8)  NULL,
    delivery_lng    DECIMAL(11, 8)  NULL,
    notes           TEXT            NULL,
    paid_at         TIMESTAMP       NULL,
    completed_at    TIMESTAMP       NULL,
    created_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)     REFERENCES users(id),
    FOREIGN KEY (merchant_id) REFERENCES merchants(id),
    INDEX idx_user_id (user_id),
    INDEX idx_merchant_id (merchant_id),
    INDEX idx_order_status (order_status)
);
```

---

## 4b. Tabel `order_items` (Detail Item per Transaksi)

```sql
CREATE TABLE order_items (
    id              BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    order_id        BIGINT UNSIGNED NOT NULL,
    food_item_id    BIGINT UNSIGNED NOT NULL,
    food_name       VARCHAR(200)    NOT NULL,                  -- Snapshot nama saat order (antisipasi item dihapus)
    original_price  DECIMAL(10, 2)  NOT NULL,                 -- Snapshot harga normal saat order
    rescue_price    DECIMAL(10, 2)  NOT NULL,                 -- Snapshot harga rescue saat order
    quantity        SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    line_total      DECIMAL(12, 2)  NOT NULL,                 -- rescue_price * quantity
    created_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (order_id)     REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (food_item_id) REFERENCES food_items(id),
    INDEX idx_order_id (order_id)
);
```

---

## 5. Tabel `deliveries` (Data Pengiriman via API Kurir)

```sql
CREATE TABLE deliveries (
    id              BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    order_id        BIGINT UNSIGNED NOT NULL UNIQUE,
    provider        ENUM('grab', 'lalamove', 'borzo') NOT NULL,
    tracking_id     VARCHAR(100)    NULL,                      -- ID tracking dari API pihak ketiga
    driver_name     VARCHAR(100)    NULL,
    driver_phone    VARCHAR(20)     NULL,
    driver_vehicle  VARCHAR(50)     NULL,
    live_tracking_url VARCHAR(255)  NULL,
    status          ENUM('searching', 'driver_found', 'picked_up', 'on_the_way', 'delivered', 'failed') NOT NULL DEFAULT 'searching',
    estimated_arrival TIMESTAMP     NULL,
    actual_arrival  TIMESTAMP       NULL,
    api_response    JSON            NULL,                      -- Raw response dari API kurir
    created_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
);
```

---

## 6. Tabel `disputes` (Pengajuan Komplain)

```sql
CREATE TABLE disputes (
    id              BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    order_id        BIGINT UNSIGNED NOT NULL,
    user_id         BIGINT UNSIGNED NOT NULL,
    merchant_id     BIGINT UNSIGNED NOT NULL,
    reason          TEXT            NOT NULL,                  -- Alasan komplain
    photo_proof     VARCHAR(255)    NOT NULL,                  -- Foto bukti
    video_proof     VARCHAR(255)    NOT NULL,                  -- Video bukti unboxing (WAJIB per PRD)
    submitted_at    TIMESTAMP       NOT NULL,                  -- Waktu submit (max 1 jam setelah terima)
    status          ENUM('pending', 'reviewing', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
    admin_notes     TEXT            NULL,
    resolved_by     BIGINT UNSIGNED NULL,                      -- ID Admin yang menyelesaikan dispute
    refund_amount   DECIMAL(12, 2)  NULL,
    resolved_at     TIMESTAMP       NULL,
    created_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (order_id)    REFERENCES orders(id),
    FOREIGN KEY (user_id)     REFERENCES users(id),
    FOREIGN KEY (merchant_id) REFERENCES merchants(id),
    FOREIGN KEY (resolved_by) REFERENCES admins(id) ON DELETE SET NULL
);
```

---

## 7. Tabel `merchant_violations` (Riwayat Pelanggaran Mitra)

```sql
CREATE TABLE merchant_violations (
    id              BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    merchant_id     BIGINT UNSIGNED NOT NULL,
    dispute_id      BIGINT UNSIGNED NOT NULL,                  -- Sumber komplain
    violation_number TINYINT        NOT NULL,                  -- Pelanggaran ke-1, 2, 3, 4
    action_taken    ENUM('warning', 'suspended_3d', 'suspended_7d', 'banned') NOT NULL,
    notes           TEXT            NULL,
    actioned_by     BIGINT UNSIGNED NULL,                      -- ID Admin yang menindak
    actioned_at     TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (merchant_id) REFERENCES merchants(id) ON DELETE CASCADE,
    FOREIGN KEY (dispute_id)  REFERENCES disputes(id),
    FOREIGN KEY (actioned_by) REFERENCES admins(id) ON DELETE SET NULL
);
```

---

## 8. Tabel `user_follows` (Fitur Follow Toko Favorit)

```sql
CREATE TABLE user_follows (
    id              BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    user_id         BIGINT UNSIGNED NOT NULL,
    merchant_id     BIGINT UNSIGNED NOT NULL,
    notify_new_item TINYINT(1)      NOT NULL DEFAULT 1,        -- Terima push notif saat ada item baru
    created_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY unique_follow (user_id, merchant_id),
    FOREIGN KEY (user_id)     REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (merchant_id) REFERENCES merchants(id) ON DELETE CASCADE
);
```

---

## 9. Tabel `notifications` (Riwayat Push Notification)

```sql
CREATE TABLE notifications (
    id              BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    user_id         BIGINT UNSIGNED NOT NULL,
    type            ENUM('new_food_item', 'order_update', 'promo', 'dispute_update', 'review_reply') NOT NULL,
    title           VARCHAR(150)    NOT NULL,
    body            TEXT            NOT NULL,
    data            JSON            NULL,                      -- Payload tambahan (misal: food_item_id)
    is_read         TINYINT(1)      NOT NULL DEFAULT 0,
    sent_at         TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_unread (user_id, is_read)
);
```

---

## 10. Tabel `wallet_transactions` (Riwayat Mutasi Saldo/Poin)

> ℹ️ **Alur Komisi:** Saat order `completed`, sistem otomatis:
> 1. Potong `commission_fee` dari `total_amount` pembayaran user.
> 2. Transfer sisa ke `wallet_balance` merchant.
> 3. Catat 2 baris di tabel ini: `commission` (untuk SaveBite) & `income` (untuk merchant).

```sql
CREATE TABLE wallet_transactions (
    id              BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    owner_type      ENUM('user', 'merchant', 'platform') NOT NULL, -- 'platform' = kas SaveBite
    owner_id        BIGINT UNSIGNED NOT NULL,
    type            ENUM('topup', 'payment', 'refund', 'withdrawal', 'commission', 'income') NOT NULL,
    amount          DECIMAL(12, 2)  NOT NULL,
    balance_before  DECIMAL(12, 2)  NOT NULL,
    balance_after   DECIMAL(12, 2)  NOT NULL,
    reference_type  ENUM('order', 'dispute', 'topup', 'withdrawal') NULL,
    reference_id    BIGINT UNSIGNED NULL,                      -- ID order atau dispute terkait
    description     VARCHAR(255)    NOT NULL,
    created_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_owner (owner_type, owner_id),
    INDEX idx_reference (reference_type, reference_id)
);
```

---

## 11. Tabel `reviews` (Rating & Ulasan Mitra)

> ℹ️ Ini adalah fitur **Akuntabilitas Mitra**. Setiap ulasan menjadi rekam jejak audit
> yang dapat dievaluasi tim SaveBite untuk pembinaan atau penindakan mitra.

```sql
CREATE TABLE reviews (
    id              BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    order_id        BIGINT UNSIGNED NOT NULL UNIQUE,           -- 1 order = max 1 ulasan
    user_id         BIGINT UNSIGNED NOT NULL,
    merchant_id     BIGINT UNSIGNED NOT NULL,
    rating          TINYINT UNSIGNED NOT NULL,                 -- Skala 1-5 bintang
    comment         TEXT            NULL,                      -- Komentar bebas dari user
    is_anonymous    TINYINT(1)      NOT NULL DEFAULT 0,        -- User bisa pilih anonim
    merchant_reply  TEXT            NULL,                      -- Balasan dari mitra
    replied_at      TIMESTAMP       NULL,
    is_flagged      TINYINT(1)      NOT NULL DEFAULT 0,        -- Ditandai admin untuk ditindak
    flag_reason     TEXT            NULL,
    created_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (order_id)    REFERENCES orders(id),
    FOREIGN KEY (user_id)     REFERENCES users(id),
    FOREIGN KEY (merchant_id) REFERENCES merchants(id),
    INDEX idx_merchant_rating (merchant_id, rating)
);
```

---

## 12. Tabel `admins` (Akun Internal Tim SaveBite)

> ℹ️ Akun admin digunakan untuk mengelola platform: approve dispute, skors mitra, verifikasi mitra baru, dan moderasi ulasan.

```sql
CREATE TABLE admins (
    id              BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    name            VARCHAR(100)    NOT NULL,
    email           VARCHAR(150)    UNIQUE NOT NULL,
    password        VARCHAR(255)    NOT NULL,
    role            ENUM('super_admin', 'moderator', 'finance') NOT NULL DEFAULT 'moderator',
    is_active       TINYINT(1)      NOT NULL DEFAULT 1,
    last_login_at   TIMESTAMP       NULL,
    created_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

---

## 13. Tabel `app_settings` (Konfigurasi Global Platform)

> ℹ️ Menyimpan parameter global SaveBite yang bisa diubah admin tanpa deploy ulang.
> Komisi platform ditetapkan **5% flat** untuk semua mitra.

```sql
CREATE TABLE app_settings (
    id              INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    setting_key     VARCHAR(100)    UNIQUE NOT NULL,           -- 'key' is reserved in MySQL
    value           TEXT            NOT NULL,
    description     VARCHAR(255)    NULL,
    updated_by      BIGINT UNSIGNED NULL,                      -- ID admin yang terakhir ubah
    updated_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (updated_by) REFERENCES admins(id) ON DELETE SET NULL
);

-- Seed data default:
-- INSERT INTO app_settings (setting_key, value, description) VALUES
--   ('commission_rate',     '5',    'Persentase komisi SaveBite dari setiap transaksi (%)'),
--   ('dispute_window_mins', '60',   'Batas waktu pengajuan komplain setelah order selesai (menit)'),
--   ('max_violation',       '4',    'Jumlah pelanggaran sebelum mitra di-banned permanen');
```

---

## Ringkasan Relasi Antar Tabel

| # | Tabel                  | Berelasi Dengan              | Jenis Relasi    |
|---|------------------------|------------------------------|-----------------|
| 1 | `users`                | `orders`                     | One-to-Many     |
| 2 | `users`                | `user_follows`               | Many-to-Many (via `user_follows`) |
| 3 | `users`                | `reviews`                    | One-to-Many     |
| 4 | `merchants`            | `food_items`                 | One-to-Many     |
| 5 | `merchants`            | `orders`                     | One-to-Many     |
| 6 | `merchants`            | `merchant_violations`        | One-to-Many     |
| 7 | `merchants`            | `reviews`                    | One-to-Many     |
| 8 | `orders`               | `order_items`                | One-to-Many     |
| 9 | `orders`               | `deliveries`                 | One-to-One      |
| 10| `orders`               | `disputes`                   | One-to-One      |
| 11| `orders`               | `reviews`                    | One-to-One      |
| 12| `disputes`             | `merchant_violations`        | One-to-One      |
| 13| `disputes`             | `admins` (resolved_by)       | Many-to-One     |
| 14| `merchant_violations`  | `admins` (actioned_by)       | Many-to-One     |
| 15| `app_settings`         | `admins` (updated_by)        | Many-to-One     |
| 16| `users`/`merchants`    | `wallet_transactions`        | Polymorphic     |

> ⚠️ **Catatan Urutan Migrasi Laravel:**
> Tabel `admins` harus dibuat **sebelum** `disputes` dan `merchant_violations` karena
> keduanya memiliki Foreign Key ke `admins`. Urutan migrasi yang benar:
>
> `users` → `admins` → `merchants` → `food_items` → `orders` → `order_items` →
> `deliveries` → `disputes` → `merchant_violations` → `user_follows` →
> `notifications` → `wallet_transactions` → `reviews` → `app_settings`

---

## Total Tabel: 14 Tabel ✅

| # | Nama Tabel              | Deskripsi Singkat                                    |
|---|-------------------------|------------------------------------------------------|
| 1 | `users`                 | Data pengguna + gamification                         |
| 2 | `merchants`             | Data mitra + status skors, anonymous & rating agregat|
| 3 | `food_items`            | Listing makanan dengan transparansi                  |
| 4 | `orders`                | Header transaksi (multi-item, komisi 5%)             |
| 5 | `order_items`           | Detail item per transaksi (snapshot harga)           |
| 6 | `deliveries`            | Data kurir & tracking API pihak ketiga               |
| 7 | `disputes`              | Komplain + bukti foto/video (window 60 menit)        |
| 8 | `merchant_violations`   | Riwayat pelanggaran & skors mitra                    |
| 9 | `user_follows`          | Follow toko + preferensi notifikasi                  |
| 10| `notifications`         | Log push notification                                |
| 11| `wallet_transactions`   | Mutasi saldo (user, merchant & komisi platform)      |
| 12| `reviews`               | Rating & ulasan untuk akuntabilitas mitra            |
| 13| `admins`                | Akun internal tim SaveBite (moderator, finance, dll) |
| 14| `app_settings`          | Konfigurasi global (komisi 5%, dispute window, dll)  |
