# SaveBite — Session Summary
**Dibuat:** 6 Mei 2026 | **Status:** Perencanaan Selesai, Siap Coding

---

## Konteks Proyek
**SaveBite** adalah aplikasi *food rescue* untuk pasar Indonesia. Menghubungkan mitra (restoran/bakery/supermarket) yang punya stok berlebih dengan konsumen yang mencari makanan berkualitas harga terjangkau.

**Tagline:** "Selamatkan Makanan, Hemat Pengeluaran"

---

## Tech Stack (Final)
| Layer | Teknologi |
|-------|-----------|
| Mobile App | Flutter (Android & iOS) |
| Backend API | Laravel (PHP 8.x) |
| Database | MySQL |
| Push Notif | Firebase Cloud Messaging (FCM) |
| Payment | Midtrans / Xendit (QRIS, E-Wallet, Transfer Bank, Wallet) |
| Logistik | GrabExpress / Lalamove API (gunakan **mock** untuk dev) |
| Maps | Google Maps Platform API |

---

## Dokumen yang Sudah Dibuat (semua di `c:\xampp\htdocs\Savebite\`)

| File | Versi | Isi |
|------|-------|-----|
| `PRD_SaveBite.md` | v1.2 | Fitur, model bisnis, logistik, dispute management |
| `DATABASE_DESIGN.md` | v1.3 | 14 tabel MySQL lengkap dengan relasi & urutan migrasi |
| `WORKFLOW_FLOWCHART.md` | v1.2 | 8 alur kerja end-to-end (Mermaid flowchart) |
| `API_DESIGN.md` | v1.0 | 59 endpoint (request, response, konvensi, route grouping) |

---

## Keputusan Bisnis Kunci

| Topik | Keputusan |
|-------|-----------|
| Komisi | 5% flat dari setiap transaksi |
| Order | 1 order = 1 mitra (seperti GoFood/GrabFood) |
| Konfirmasi Order | **Auto-confirm** setelah bayar (mitra tidak perlu tekan tombol) |
| Gagal Kurir | Tawarkan **self-pickup** → jika tolak → cancel + refund 100% |
| Toko Anonymous | Tidak bisa self-pickup (identitas rahasia) |
| Dispute | Wajib foto **dan** video unboxing, batas 60 menit setelah delivered |
| Skors Mitra | 4 tahap: Warning → 3 hari → 7 hari → Banned permanen |
| Wallet Top-Up | Via Payment Gateway (QRIS/E-Wallet/VA), dikonfirmasi via webhook |

---

## Database: 14 Tabel

`users` → `admins` → `merchants` → `food_items` → `orders` → `order_items` → `deliveries` → `disputes` → `merchant_violations` → `user_follows` → `notifications` → `wallet_transactions` → `reviews` → `app_settings`

> ⚠️ Urutan di atas adalah urutan migrasi Laravel yang wajib diikuti (foreign key constraint).

---

## API: 59 Endpoint (13 Modul)

| Modul | Jumlah |
|-------|--------|
| Auth User | 7 |
| Auth Merchant | 7 |
| Food Items (User browse) | 3 |
| Food Items (Merchant CRUD) | 5 |
| Orders (User) | 5 |
| Orders (Merchant) | 2 |
| Deliveries & Tracking | 2 |
| Webhooks (Midtrans & Kurir) | 2 |
| Reviews | 3 |
| Disputes | 2 |
| Follow & Notifications | 5 |
| Wallet | 6 |
| Admin Panel | 10 |
| **TOTAL** | **59** |

**Base URL:** `http://localhost:8000/api/v1`  
**Auth:** Laravel Sanctum (Bearer Token), 3 guard: `role:user`, `role:merchant`, `role:admin`

---

## Status Implementasi
- [x] PRD selesai
- [x] Database Design selesai
- [x] Workflow Flowchart selesai
- [x] API Endpoint Design selesai
- [ ] **Setup project Laravel** ← Next step
- [ ] Buat migrations (ikuti urutan 14 tabel)
- [ ] Buat Models & API Controllers
- [ ] Setup Flutter project
- [ ] Integrasi FCM
- [ ] Mock API kurir untuk development

---

## Detail Teknis Penting (Referensi Cepat Saat Coding)

### Enum Values
```
orders.order_status    : pending | confirmed | picked_up | delivered | completed | cancelled
orders.payment_method  : wallet | qris | e_wallet | bank_transfer
orders.payment_status  : pending | paid | failed | refunded
deliveries.status      : searching | driver_found | picked_up | on_the_way | delivered | failed
disputes.status        : pending | reviewing | approved | rejected
merchants.status       : active | suspended | banned
merchants.category     : fast_food | bakery | supermarket
food_items.status      : available | sold_out | expired | cancelled
admins.role            : super_admin | moderator | finance
```

### Format & Kalkulasi Otomatis Backend
| Field | Aturan |
|-------|--------|
| `order_code` | Format: `SB-YYYYMMDD-XXXX` (contoh: `SB-20260506-0001`) |
| `food_items.discount_pct` | Dihitung otomatis: `round((original - rescue) / original * 100)` |
| `orders.commission_fee` | `subtotal * 0.05` (ambil dari `app_settings` key `commission_rate`) |
| `orders.total_amount` | `subtotal + delivery_fee` (komisi **tidak** ditambah ke total user) |
| `orders.savings_amount` | `SUM((original_price - rescue_price) * qty)` per item |
| Merchant wallet | Di-update saat `order_status = completed`: `+= subtotal - commission_fee` |

### Default `app_settings`
| setting_key | value | Keterangan |
|-------------|-------|------------|
| `commission_rate` | `5` | Persen komisi SaveBite |
| `dispute_window_mins` | `60` | Batas waktu ajukan komplain (menit) |
| `max_violation` | `4` | Pelanggaran sebelum banned permanen |

### Aturan Anonymous Merchant
- `merchants.name` = nama asli (TIDAK pernah dikirim ke endpoint user)
- `merchants.display_name` = nama publik (NULL jika anonymous, sistem generate nama samaran)
- Toko anonymous **tidak bisa** self-pickup
- Driver tetap mendapat `merchants.address` lengkap

### Lifecycle Order → Trigger Aksi
| Status Berubah | Aksi Backend |
|---|---|
| `pending` → `confirmed` | Panggil API kurir + notif mitra |
| `confirmed` → `cancelled` | Refund ke wallet + kembalikan stok |
| `delivered` → `completed` | Transfer dana ke wallet mitra + update gamification user |
| Auto-complete | Jika 1 jam setelah `delivered` tidak ada konfirmasi user |

---

## Cara Lanjut di Sesi Baru

Cukup paste prompt ini:

> "Saya sedang mengerjakan proyek **SaveBite** (food rescue app). Semua dokumen perencanaan sudah ada di `c:\xampp\htdocs\Savebite\`. Tolong baca `SESSION_SUMMARY.md` di folder tersebut untuk konteks, lalu bantu saya mulai setup project Laravel dan migrasi database."
