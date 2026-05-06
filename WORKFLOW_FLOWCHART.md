# Alur Kerja (Workflow) - SaveBite
**Versi:** 1.2  
**Date:** 6 Mei 2026  
**Changelog v1.1:** Fix hitung harga, auto-confirm order, alur self-pickup, alur top-up wallet, aturan 1 order = 1 mitra.  
**Changelog v1.2:** Fix delivery status detail, video wajib untuk dispute, bank_transfer di checkout, self-pickup lifecycle.

---

## Gambaran Umum Alur

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│  MITRA   │ ──▶ │ SAVEBITE │ ──▶ │   USER   │ ──▶ │  KURIR   │ ──▶ │  SELESAI │
│  Upload  │     │ Platform │     │  Pesan   │     │  Antar   │     │  Review  │
└──────────┘     └──────────┘     └──────────┘     └──────────┘     └──────────┘
```

> ⚠️ **Aturan Penting:** 1 order = 1 mitra. Jika user ingin beli dari 2 toko berbeda,
> harus buat 2 order terpisah (seperti GoFood/GrabFood).

---

## Alur 1: Mitra Mengunggah Makanan

> Mitra memiliki stok berlebih atau toko akan segera tutup.

```mermaid
flowchart TD
    A["🏪 Mitra buka Merchant App"] --> B["📝 Isi detail makanan"]
    B --> C{"Apakah data lengkap?"}
    C -- "Tidak" --> B
    C -- "Ya" --> D["📤 Submit listing makanan"]
    
    D --> E["✅ Status: 'available'"]
    D --> F["🔔 Sistem cek: Siapa yang follow toko ini?"]
    
    F --> G{"Ada follower?"}
    G -- "Tidak" --> H["Makanan tampil di feed umum saja"]
    G -- "Ya" --> I["📲 Kirim Push Notification via FCM"]
    I --> J["'Bakery favoritmu baru saja upload 5 Roti Croissant!'"]
    J --> H
    
    E --> H
```

### Detail Data yang Wajib Diisi Mitra:
| Field | Contoh | Wajib? |
|-------|--------|--------|
| Nama Makanan | Roti Croissant Coklat | ✅ |
| Foto | upload gambar | ❌ (tapi disarankan) |
| Harga Normal | Rp 35.000 | ✅ |
| Harga Rescue | Rp 15.000 | ✅ |
| Stok Tersedia | 5 porsi | ✅ |
| Alasan Diskon | "Toko tutup 30 menit lagi" | ✅ |
| Waktu Produksi | 06:00 pagi ini | ✅ (untuk siap saji) |
| Tanggal Kedaluwarsa | 07 Mei 2026 | ✅ (untuk kemasan) |

---

## Alur 2: User Memesan Makanan

> User mendapat notifikasi atau browsing feed, lalu memilih makanan.

```mermaid
flowchart TD
    A["👤 User buka SaveBite App"] --> B{"Dari mana?"}
    B -- "Push Notif" --> C["Langsung ke halaman makanan"]
    B -- "Browse Feed" --> D["Lihat daftar makanan nearby"]
    D --> C
    
    C --> E["👀 Lihat detail: harga, foto, alasan, waktu produksi"]
    E --> F{"Mau beli?"}
    F -- "Tidak" --> D
    F -- "Ya" --> G["🛒 Tambah ke keranjang"]
    
    G --> H{"Tambah item lain dari toko yang SAMA?"}
    H -- "Ya" --> D
    H -- "Tidak" --> I["📋 Halaman Checkout"]
    
    I --> J["Masukkan alamat pengiriman"]
    J --> K["Sistem hitung ongkir via API kurir"]
    K --> L["Tampilkan ringkasan order"]
```

### Tampilan Ringkasan Order:
```
┌──────────────────────────────────────────────────────┐
│               RINGKASAN PESANAN                      │
├──────────────────────────────────────────────────────┤
│ 🥐 Roti Croissant Coklat  x2                        │
│    Normal: Rp 70.000 → Rescue: Rp 30.000            │
│ 🍰 Slice Cheesecake       x1                        │
│    Normal: Rp 35.000 → Rescue: Rp 20.000            │
├──────────────────────────────────────────────────────┤
│ Subtotal                              Rp 50.000      │
│ Ongkir (GrabExpress)                  Rp 12.000      │
├──────────────────────────────────────────────────────┤
│ TOTAL BAYAR                           Rp 62.000      │
│ Anda hemat              Rp 55.000 (dari Rp 105.000) │
├──────────────────────────────────────────────────────┤
│            [ Bayar Sekarang 💳 ]                     │
└──────────────────────────────────────────────────────┘
```

---

## Alur 3: Pembayaran & Auto-Confirm Order

> Order otomatis dikonfirmasi setelah pembayaran berhasil.
> Mitra **tidak perlu** menekan tombol "Terima" — cukup siapkan makanan.

```mermaid
flowchart TD
    A["💳 User pilih metode bayar"] --> B{"Metode?"}
    B -- "Wallet SaveBite" --> C{"Saldo cukup?"}
    C -- "Tidak" --> D["❌ 'Saldo tidak cukup, silakan top-up'"]
    C -- "Ya" --> E["✅ Potong saldo wallet"]
    
    B -- "QRIS / E-Wallet" --> F["🔗 Redirect ke Payment Gateway"]
    B -- "Transfer Bank" --> F2["🏦 Tampilkan Virtual Account"]
    F --> G{"Pembayaran berhasil?"}
    F2 --> G
    G -- "Tidak/Timeout" --> H["❌ Order gagal, stok dikembalikan"]
    G -- "Ya" --> E
    
    E --> I["📝 Buat record 'orders' + 'order_items'"]
    I --> J["🔢 Kurangi stok di 'food_items'"]
    J --> K["✅ Status order: 'confirmed' (otomatis)"]
    K --> L["📲 Notif ke Mitra: 'Ada pesanan baru, siapkan makanan!'"]
    K --> M["🚀 Langsung panggil API kurir"]
```

### Alur Mutasi Wallet Saat Pembayaran:
```
┌─────────────────────────────────────────────────────┐
│  wallet_transactions (untuk user)                   │
├─────────────────────────────────────────────────────┤
│  type: 'payment'                                    │
│  amount: -62.000                                    │
│  balance_before: 100.000                            │
│  balance_after: 38.000                              │
│  description: 'Pembayaran order SB-20260506-0001'   │
└─────────────────────────────────────────────────────┘
```

---

## Alur 4: Pengiriman via Kurir (Inti Proses)

> Ini adalah alur kritis: bagaimana makanan berpindah dari dapur mitra ke tangan user.

```mermaid
flowchart TD
    A["✅ Order confirmed"] --> B["🚀 Sistem panggil API Kurir"]
    B --> C["Kirim request ke GrabExpress/Lalamove API"]
    C --> D{"API response?"}
    
    D -- "Error/Timeout" --> E["🔄 Retry 3x"]
    E --> E2{"Masih gagal?"}
    E2 -- "Tidak, berhasil" --> F
    E2 -- "Ya, gagal total" --> E3["📲 Tawarkan self-pickup ke user"]
    E3 --> E4{"User mau self-pickup?"}
    E4 -- "Ya" --> E5["📍 Tampilkan alamat toko + petunjuk arah"]
    E5 --> E7["🚶 User ambil sendiri di toko"]
    E7 --> T
    E4 -- "Tidak" --> E6["❌ Cancel order + refund 100%"]
    
    D -- "Sukses" --> F["📝 Simpan tracking_id di tabel 'deliveries'"]
    
    F --> G["⏳ Delivery status: 'searching'"]
    G --> H["🏍️ Delivery status: 'driver_found'"]
    H --> I["📝 Simpan nama, HP, kendaraan driver"]
    I --> J["📲 Notif ke User: 'Kurir sedang menuju toko'"]
    
    J --> K["🏪 Driver tiba di toko mitra"]
    K --> L["📦 Mitra serahkan makanan ke driver"]
    L --> M["✅ Delivery status: 'picked_up' / Order status: 'picked_up'"]
    M --> N["📲 Notif ke User: 'Makanan sudah diambil kurir!'"]
    
    N --> O["🏍️ Driver menuju alamat user"]
    O --> P["✅ Delivery status: 'on_the_way'"]
    P --> Q["📍 User bisa live-tracking via URL"]
    
    Q --> R["🏠 Driver tiba di alamat user"]
    R --> S["✅ Delivery status: 'delivered'"]
    S --> T["✅ Order status: 'delivered'"]
```

### Detail Integrasi API Kurir:
```
┌──────────────────────────────────────────────────────┐
│  REQUEST ke GrabExpress API                          │
├──────────────────────────────────────────────────────┤
│  POST /v1/deliveries                                 │
│  {                                                   │
│    "origin": {                                       │
│      "address": "Jl. Sudirman No.10 (alamat mitra)", │
│      "lat": -6.2088,                                 │
│      "lng": 106.8456                                 │
│    },                                                │
│    "destination": {                                  │
│      "address": "Jl. Gatot Subroto (alamat user)",   │
│      "lat": -6.2350,                                 │
│      "lng": 106.8200                                 │
│    },                                                │
│    "package": {                                      │
│      "description": "Makanan - Handle with care",    │
│      "weight": 1                                     │
│    }                                                 │
│  }                                                   │
├──────────────────────────────────────────────────────┤
│  ⚠️ Catatan untuk Anonymous Merchant:                │
│  Identitas toko TIDAK dikirim ke user.               │
│  User hanya lihat: "Pesanan dari Bakery Anonim"      │
│  Tapi driver tetap dapat alamat lengkap toko.        │
│                                                      │
│  ⚠️ Catatan untuk Self-Pickup:                       │
│  Jika user pilih self-pickup, alamat toko            │
│  ditampilkan KECUALI toko berstatus anonymous.       │
│  Toko anonymous tidak mendukung self-pickup.         │
└──────────────────────────────────────────────────────┘
```

---

## Alur 5: Order Selesai & Pembagian Dana

> Setelah makanan diterima user, dana dibagi antara mitra dan SaveBite.

```mermaid
flowchart TD
    A["🏠 Makanan sampai ke user"] --> B["⏱️ Tunggu konfirmasi user (atau auto-complete 1 jam)"]
    B --> C["✅ Status order: 'completed'"]
    
    C --> D["💰 Sistem hitung pembagian dana"]
    D --> E["Subtotal: Rp 50.000"]
    E --> F["Komisi SaveBite 5%: Rp 2.500"]
    E --> G["Pendapatan Mitra: Rp 47.500"]
    
    F --> H["📝 wallet_transactions: type='commission', owner='platform'"]
    G --> I["📝 wallet_transactions: type='income', owner='merchant'"]
    I --> J["💰 Update merchants.wallet_balance += 47.500"]
    
    C --> K["📊 Update gamification user"]
    K --> L["total_saved += Rp 55.000"]
    K --> M["total_rescued += 3 porsi"]
    
    C --> N["📲 Notif ke User: 'Selesai! Beri rating untuk toko ini?'"]
```

### Ilustrasi Pembagian Dana:
```
 User bayar: Rp 62.000
        │
        ├── Ongkir Rp 12.000 ──────▶ Langsung ke kurir (via API)
        │
        └── Subtotal Rp 50.000
                │
                ├── 5% = Rp 2.500 ──▶ 💼 Kas SaveBite (platform)
                │
                └── 95% = Rp 47.500 ─▶ 🏪 Wallet Mitra
```

---

## Alur 6: Review & Rating (Post-Order)

```mermaid
flowchart TD
    A["📲 Notif: 'Beri rating?'"] --> B{"User mau review?"}
    B -- "Tidak" --> C["Selesai (review opsional)"]
    B -- "Ya" --> D["⭐ Pilih bintang 1-5"]
    
    D --> E["💬 Tulis komentar (opsional)"]
    E --> F{"Ingin review anonim?"}
    F -- "Ya" --> G["is_anonymous = 1"]
    F -- "Tidak" --> H["is_anonymous = 0"]
    
    G --> I["📝 Simpan ke tabel 'reviews'"]
    H --> I
    
    I --> J["📊 Update merchants.average_rating"]
    I --> K["📊 Update merchants.total_reviews += 1"]
    
    I --> L["📲 Notif ke Mitra: 'Ada ulasan baru'"]
    L --> M{"Mitra mau balas?"}
    M -- "Ya" --> N["💬 Tulis balasan (merchant_reply)"]
    M -- "Tidak" --> O["Selesai"]
    N --> P["📲 Notif ke User: 'Mitra membalas ulasan Anda'"]
    P --> O
```

---

## Alur 7: Komplain & Dispute (Jika Bermasalah)

```mermaid
flowchart TD
    A["😠 User terima makanan bermasalah"] --> B{"Masih dalam 60 menit?"}
    B -- "Tidak" --> C["❌ Tidak bisa ajukan komplain"]
    B -- "Ya" --> D["📸 Ambil Foto bukti (WAJIB)"]
    
    D --> E["📹 Ambil Video unboxing (WAJIB)"]
    E --> F["📝 Tulis alasan komplain"]
    F --> G["📤 Submit dispute"]
    
    G --> H["⏳ Status dispute: 'pending'"]
    H --> I["📲 Notif ke Admin: 'Ada komplain baru'"]
    
    I --> J["👨‍💼 Admin review bukti"]
    J --> K{"Bukti valid?"}
    
    K -- "Tidak valid" --> L["❌ Status: 'rejected'"]
    L --> M["📲 Notif ke User: 'Komplain ditolak'"]
    
    K -- "Valid" --> N["✅ Status: 'approved'"]
    N --> O["💰 Refund 100% ke wallet/poin user"]
    O --> P["📲 Notif ke User: 'Refund Rp 50.000 berhasil'"]
    
    N --> Q["⚠️ Tambah violation_count mitra"]
    Q --> R{"Pelanggaran ke berapa?"}
    
    R -- "1" --> S["📝 Warning: Teguran tertulis"]
    R -- "2" --> T["⏸️ Suspended 3 hari"]
    R -- "3" --> U["⏸️ Suspended 7 hari + investigasi"]
    R -- "4" --> V["🚫 BANNED permanen"]
```

---

## Alur 8: Top-Up Wallet SaveBite (BARU)

```mermaid
flowchart TD
    A["👤 User buka menu 'Wallet'"] --> B["Lihat saldo saat ini"]
    B --> C["Tekan 'Top-Up'"]
    C --> D["Pilih nominal: 50rb / 100rb / 200rb / custom"]
    D --> E{"Metode top-up?"}
    
    E -- "QRIS" --> F["📱 Tampilkan QR Code dari Payment Gateway"]
    E -- "E-Wallet (GoPay/OVO/DANA)" --> G["🔗 Redirect ke aplikasi e-wallet"]
    E -- "Transfer Bank" --> H["🏦 Tampilkan VA number dari Payment Gateway"]
    
    F --> I{"Pembayaran masuk?"}
    G --> I
    H --> I
    
    I -- "Tidak/Expired" --> J["❌ Top-up gagal"]
    I -- "Ya (webhook dari Midtrans/Xendit)" --> K["✅ Tambah saldo wallet"]
    
    K --> L["📝 wallet_transactions: type='topup'"]
    L --> M["📲 Notif: 'Top-up Rp 100.000 berhasil!'"]
```

---

## Ringkasan Status Order (Lifecycle)

```
                                                    ┌───────────┐
                                                    │ cancelled │
                                                    │  (batal)  │
                                                    └───────────┘
                                                          ▲
                                                          │
┌─────────┐    ┌───────────┐    ┌───────────┐    ┌───────────┐    ┌───────────┐
│ pending  │──▶│ confirmed │──▶│ picked_up │──▶│ delivered │──▶│ completed │
│(bayar)   │    │(auto+kurir)│   │(kurir amb.)│   │ (sampai)  │    │ (selesai) │
└─────────┘    └───────────┘    └───────────┘    └───────────┘    └───────────┘
                     │
                     └──▶ [self-pickup] ──▶ delivered ──▶ completed
```

### Kapan Status Berubah:
| Dari | Ke | Pemicu |
|------|----|--------|
| `pending` | `confirmed` | Pembayaran berhasil (otomatis, tanpa konfirmasi mitra) |
| `confirmed` | `picked_up` | Driver kurir mengambil makanan dari toko |
| `confirmed` | `delivered` | User self-pickup langsung di toko (jika kurir gagal) |
| `picked_up` | `delivered` | Driver sampai di alamat user |
| `delivered` | `completed` | User konfirmasi terima **ATAU** auto-complete setelah 1 jam |
| `confirmed` | `cancelled` | Driver tidak ditemukan + user tolak self-pickup, atau stok habis |

---

## Diagram Waktu (Timeline Tipikal)

```
Waktu ──────────────────────────────────────────────────────────▶

20:30   Mitra upload "5x Roti Croissant" (toko tutup jam 21:00)
  │
20:30   Push Notif ke 23 follower: "Ada Croissant baru!"
  │
20:32   User A pesan 2x Croissant + 1x Cheesecake
  │
20:32   Pembayaran via QRIS ✅ → Order auto-confirmed
  │
20:32   API kurir dipanggil + Notif ke Mitra: "Siapkan makanan!"
  │
20:35   Driver ditemukan, menuju toko
  │
20:42   Driver tiba di toko, ambil makanan
  │
20:55   Makanan sampai di User A ✅
  │
20:56   User A beri rating ⭐⭐⭐⭐⭐
  │
20:56   Dana dibagi: Rp 47.500 → Mitra, Rp 2.500 → SaveBite
```
