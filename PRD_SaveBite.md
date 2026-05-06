# Product Requirements Document (PRD) - SaveBite

**Project Name:** SaveBite  
**Tagline:** "Selamatkan Makanan, Hemat Pengeluaran"  
**Status:** Draft (V1.2)  
**Date:** 6 Mei 2026  

---

## 1. Pendahuluan (Executive Summary)
SaveBite adalah platform *food rescue* berbasis aplikasi yang menghubungkan mitra (Fast Food, Bakery, Supermarket) yang memiliki stok makanan berlebih dengan konsumen (Mahasiswa & Menengah) yang mencari makanan berkualitas dengan harga terjangkau. Fokus utama aplikasi ini adalah mengurangi limbah makanan (*food waste*) di Indonesia dengan model bisnis yang transparan dan efisien.

## 2. Target Audiens
- **Konsumen:** Mahasiswa dan pekerja kantoran yang mencari makanan "bermerek" dengan harga *affordable*.
- **Mitra:** Merchant berskala besar (Fast Food, Bakery, Supermarket) yang memiliki tantangan dalam manajemen stok berlebih.

## 3. Fitur Utama (Core Features)

### A. Sisi Pengguna (Customer App)
1. **Transparansi Produk:** Setiap item wajib mencantumkan:
   - Waktu Produksi.
   - Tanggal Kedaluwarsa (khusus kemasan).
   - Alasan Diskon (Toko mau tutup, kelebihan produksi, dll).
2. **Anonymous Merchant:** Kemampuan membeli dari toko tanpa mengetahui nama brand aslinya (untuk melindungi reputasi mitra besar).
3. **Follow & Push Notification:** Pengguna bisa mengikuti toko favorit dan mendapatkan notifikasi instan saat stok makanan diunggah.
4. **Gamification Profil:** Menampilkan pencapaian personal:
   - **Total Uang yang Dihemat (Rp)**.
   - **Total Porsi Makanan Diselamatkan**.
5. **Multi-Item Checkout:** Pengguna dapat membeli lebih dari 1 jenis makanan dari mitra yang sama dalam 1 transaksi.
6. **Rating & Ulasan Mitra:** Pengguna dapat memberi rating bintang (1-5) dan komentar setelah order selesai. Ulasan bersifat opsional anonim dan menjadi rekam jejak **akuntabilitas** mitra.

### B. Sisi Mitra (Merchant App/Dashboard)
1. **Quick Upload:** Antarmuka khusus mitra (mirip aplikasi ojol) untuk mengunggah sisa makanan dengan cepat di jam-jam tertentu.
2. **Manajemen Stok:** Mengatur jumlah porsi yang tersedia secara *real-time*.
3. **Balasan Ulasan:** Mitra dapat membalas ulasan pengguna secara publik untuk menunjukkan tanggung jawab.

## 4. Logistik & Pembayaran
- **Pengiriman:** Integrasi API pihak ketiga (GrabExpress/Lalamove/Borzo) untuk pengiriman instan. Mendukung fitur *Toko Anonim* karena kurir yang mengambil langsung.
- **Self-Pickup:** Jika driver tidak ditemukan, user ditawari ambil sendiri di toko (tidak berlaku untuk toko anonymous).
- **Metode Pembayaran:** SaveBite Wallet, QRIS, E-Wallet (GoPay/OVO/DANA), atau Transfer Bank (Virtual Account).
- **Auto-Confirm:** Order otomatis dikonfirmasi setelah pembayaran berhasil — mitra tidak perlu menekan tombol "Terima".
- **Aturan Order:** 1 order = 1 mitra. Jika ingin beli dari toko berbeda, user buat order terpisah.

## 5. Model Bisnis (Revenue)
- **Komisi Platform:** SaveBite mengambil komisi **5% flat** dari setiap transaksi yang berhasil.
- **Alur:** `Total Pembayaran User` → Komisi 5% masuk kas SaveBite → Sisa 95% masuk wallet mitra.
- **Tarif:** Seragam untuk semua mitra, dapat diubah oleh admin melalui panel konfigurasi.

## 6. Manajemen Sengketa & Kualitas (Dispute Management)
Untuk menjaga kepercayaan pengguna, SaveBite menerapkan kebijakan ketat:
1. **Syarat Refund:** Pengguna wajib melampirkan **Foto & Video Unboxing** maksimal 1 jam setelah status pengiriman "Selesai".
2. **Kompensasi:** Refund 100% diberikan dalam bentuk **Poin/Saldo Aplikasi**.
3. **Sistem Skors Mitra:**
   - **Pelanggaran 1:** Peringatan keras & teguran tertulis.
   - **Pelanggaran 2:** Skors 3 hari (toko tidak bisa mengunggah makanan).
   - **Pelanggaran 3:** Skors 7 hari + Investigasi kualitas.
   - **Pelanggaran 4:** Banned permanen dari platform.

## 7. Teknologi Utama (Tech Stack)
Berdasarkan kebutuhan skalabilitas dan fitur notifikasi push:
- **Frontend (Mobile):** Flutter (Android & iOS).
- **Backend (API & Admin):** Laravel (PHP 8.x).
- **Database:** MySQL (via XAMPP/Local Environment).
- **Infrastruktur & Layanan Pihak Ketiga:** 
  - **Push Notifications:** Firebase Cloud Messaging (FCM).
  - **Payment Gateway:** Midtrans atau Xendit (Fokus ke QRIS & E-Wallet).
  - **Maps & Geolocation:** Google Maps Platform API.
  - **Logistics:** GrabExpress / Lalamove API integration.
