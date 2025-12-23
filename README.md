
---

# Naik — Platform Penjualan Peralatan Olahraga

## 1. Nama Anggota Kelompok

* **Bryan Christopher Kurniadi** – 2406346011
* **Naik** – 2406435805
* **Hammam Muhammad Mubarak** – 2406401350
* **Jessevan Gerard Vito Uisan** – 2406495496
* **Raymundo Rafaelito** – 2406404642

---

## 2. Deskripsi Website, Daftar Modul, dan Deskripsi Modul

**Naik /na·ik/** adalah platform digital inovatif di bidang penjualan peralatan olahraga secara online. Platform ini hadir sebagai tempat terbaik bagi pecinta olahraga untuk mencari, membandingkan, dan membeli perlengkapan favorit mereka dengan mudah dan aman. Terinspirasi oleh semangat olahraga dan gaya hidup aktif, Naik menyediakan berbagai fitur unggulan yang dikembangkan secara kolaboratif oleh tim.

### a. Ulasan dan Komentar – *Raymundo Rafaelito*

Fitur ini memungkinkan pengguna membaca dan menulis ulasan jujur pada produk. Membantu calon pembeli mengambil keputusan berdasarkan pengalaman pengguna lain.

### b. Filter Produk – *Naik*

Memudahkan pengguna menyaring produk berdasarkan kategori, harga, merek, hingga jenis olahraga. Cocok untuk mencari produk terbaik sesuai kebutuhan.

### c. Sistem Lelang dan Keranjang – *Jessevan Gerard Vito Uisan*

Pengguna dapat menawar harga barang dalam sistem lelang terbuka, serta menyimpan produk pre-loved berkualitas dalam keranjang untuk checkout nanti.

### d. Checkout Page – *Hammam Muhammad Mubarak*

Pengguna dapat memilih metode pembayaran, jenis pengiriman, menambahkan catatan, hingga menggunakan opsi asuransi barang.

### e. Chat Pembeli dan Penjual – *Bryan Christopher Kurniadi*

Fitur chat real-time untuk komunikasi langsung antara pembeli dan penjual, seperti menawar harga atau menanyakan detail produk.

Naik ingin menjadi platform lokal yang mendorong gaya hidup aktif dan sehat, dengan akses mudah terhadap produk olahraga berkualitas. Naik bukan sekadar toko, tetapi gerakan.

---

## 3. Jenis Pengguna Website

### a. Pembeli

Pengguna umum yang ingin menjelajah, mencari, dan membeli produk.

**Fitur & Hak Akses:**

* Melihat daftar produk dan detailnya
* Menggunakan fitur filter produk
* Memberikan ulasan
* Mengikuti lelang produk
* Membeli langsung (buy now) atau bidding
* Melihat riwayat transaksi
* Chat dengan penjual
* Mengatur profil dan metode pembayaran

---

### b. Penjual

Untuk individu atau toko yang ingin menjual produk olahraga.

**Fitur & Hak Akses:**

* Semua fitur pembeli
* Mengunggah dan mengelola produk
* Menentukan mode penjualan (normal atau bidding)
* Menerima dan merespon chat pembeli
* Melihat laporan penjualan
* Mengatur pengiriman
* Menanggapi ulasan pembeli

---

### c. Admin

Pihak internal Naik yang mengontrol sistem dan keamanan platform.

**Fitur & Hak Akses:**

* Akses penuh ke data pengguna, produk, transaksi, dan statistik
* Menyetujui atau menolak akun penjual baru
* Menghapus atau menyembunyikan produk melanggar aturan
* Moderasi ulasan, komentar, dan chat
* Mengelola laporan pendapatan
* Menangani masalah teknis dan pengembalian dana
* Konfigurasi backend (fitur, kategori, promosi, dll)

---

## 4. Alur Pengintegrasian Web Service (Flutter ↔ Django)

### a. Persiapan Backend (Django)

1. Install dan konfigurasi `django-cors-header`

   ```bash
   pip install django-cors-headers
   ```
2. Tambahkan ke `INSTALLED_APPS` dan `MIDDLEWARE`
3. Setelan pada `settings.py`:

   ```python
   CSRF_TRUSTED_ORIGINS = ["http://localhost", "http://127.0.0.1", "http://10.0.2.2"]
   ```
4. Membuat endpoint JSON

   * Setiap anggota membuat atau memodifikasi view baru di `views.py` sesuai modul masing-masing

---

### b. Persiapan Frontend (Flutter)

1. Install library yang diperlukan
2. Membuat model data (Konversi JSON ke Dart)

   * JSON dari Django harus dikonversi menjadi file `.dart` menggunakan tools seperti QuickType

---

### c. Alur Integrasi per Fitur

1. Autentikasi (Login/Register)
2. Filter Product
3. Ulasan dan Komentar
4. Sistem Lelang
5. Checkout Page
6. Chat Pembeli dan Penjual

---

## Link Figma

[https://www.figma.com/team_invite/redeem/SqRdQdOKUpWhPSU0bTmWad](https://www.figma.com/team_invite/redeem/SqRdQdOKUpWhPSU0bTmWad)

---
Tes Trigger Bitrise
