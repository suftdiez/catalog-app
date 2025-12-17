📱 MyGadget Store - Aplikasi Katalog Gadget (Flutter)

Versi: 1.0.0
Dibuat oleh: [Nama Anda]
Teknologi: Flutter (Dart)

📖 1. Gambaran Umum (Overview)

MyGadget Store adalah aplikasi mobile berbasis Flutter yang berfungsi sebagai katalog produk elektronik sederhana. Aplikasi ini dikembangkan secara bertahap mengikuti kurikulum "Dasar-Dasar Perancangan Aplikasi Mobile", mulai dari pengenalan widget dasar hingga integrasi API dan manajemen state.

Tujuan Aplikasi:

Menampilkan daftar produk gadget (HP, Laptop, Aksesoris).

Memungkinkan pengguna menambah dan menghapus data produk.

Mengintegrasikan data dari Internet (API) dan Penyimpanan Lokal.

Memberikan pengalaman pengguna yang interaktif dengan fitur pencarian dan detail produk.

📂 2. Struktur Proyek (Architecture)

Aplikasi ini menggunakan struktur folder yang memisahkan antara UI (Tampilan) dan Logic (Logika Bisnis) untuk memudahkan pengembangan lebih lanjut.

lib/
├── providers/                 # FOLDER LOGIKA (State Management)
│   └── product_provider.dart  # Mengatur data produk, API, Search, & Storage
├── main.dart                  # FOLDER UI (Semua Halaman & Widget)
└── generated_plugin_registrant.dart


Detail File:

A. lib/main.dart (UI Layer)

File ini berisi seluruh antarmuka pengguna, terdiri dari beberapa class:

MyGadgetApp: Widget root yang mengatur tema dan routing awal (Login vs Home).

LoginPage: Halaman autentikasi sederhana dengan validasi input.

LandingPage: Halaman beranda dengan Slider Banner dan Menu Utama.

CatalogPage: Halaman daftar produk dengan fitur Search dan Swipe-to-Delete.

DetailPage: Halaman rincian produk (Gambar besar, Deskripsi).

AddProductPage: Form untuk menambah produk baru (Dropdown, Radio Button).

AboutPage: Halaman informasi tentang aplikasi.

ProfileCard: Widget kustom untuk menampilkan profil user.

B. lib/providers/product_provider.dart (Logic Layer)

File ini menangani semua urusan data:

fetchFromApi(): Mengambil data JSON dari fakestoreapi.com.

loadData(): Mengecek apakah ada data di HP (Local), jika tidak ada baru ambil API.

search(query): Memfilter list produk berdasarkan kata kunci.

addProduct() & removeProduct(): Menambah/Hapus data dari list dan menyimpannya permanen.

_saveToLocal(): Menyimpan seluruh list ke SharedPreferences dalam format JSON.

🛠 3. Teknologi & Dependensi

Berikut adalah daftar library eksternal yang digunakan dalam pubspec.yaml:

Package

Versi

Kegunaan

Bab Terkait

http

^1.1.0

Mengambil data produk dari API Internet.

Bab 3.2

provider

^6.1.1

Mengelola State (Data) agar bisa diakses semua halaman.

Bab 5

shared_preferences

^2.2.2

Menyimpan status Login & Data Produk di memori HP.

Bab 4.1

carousel_slider

^5.0.0

Membuat banner gambar bergerak otomatis di Home.

Bab 4.2

url_launcher

^6.2.1

Membuka link website/WA di browser eksternal.

Bab 4.2

🚀 4. Fitur & Alur Kerja (Per Bab)

BAB 1: Fondasi & Layout

Implementasi: Membuat LandingPage dengan widget Column, Row, dan Container.

Fitur: Tampilan awal yang rapi dengan ProfileCard (Foto & Nama).

BAB 2: Navigasi & List

Implementasi: Membuat CatalogPage menggunakan ListView.builder.

Fitur:

Navigasi antar halaman (Navigator.push).

Tampilan daftar produk dalam bentuk Kartu (Card).

Swipe-to-Dismiss: Geser item ke kiri untuk menghapus.

BAB 3: Data & Interaksi

Implementasi: Membuat AddProductPage dan LoginPage.

Fitur:

Form Validasi: Mencegah input kosong di halaman Login & Tambah Produk.

Variasi Input: Menggunakan Dropdown (Kategori) dan Radio Button (Kondisi).

API Networking: Mengambil data asli dari FakeStoreAPI (Elektronik).

BAB 4: Penyimpanan & Optimasi

Implementasi: Integrasi shared_preferences.

Fitur:

Persistent Login: User tidak perlu login ulang setelah aplikasi ditutup.

Offline Capability: Data produk disimpan lokal, jadi bisa dibuka tanpa internet (setelah load pertama).

Banner Slider: Tampilan visual menarik di halaman depan.

BAB 5: Integrasi & Publikasi

Implementasi: Refactoring ke Provider dan fitur pelengkap.

Fitur:

Live Search: Mencari produk tanpa loading ulang.

Detail Page: Halaman khusus untuk melihat detail barang.

Build APK: Aplikasi siap diinstal di HP Android (app-release.apk).

💻 5. Cara Menjalankan Proyek (Untuk Developer Lain)

Jika Anda ingin melanjutkan pengembangan proyek ini di komputer lain, ikuti langkah berikut:

Prasyarat:

Flutter SDK terinstal.

Android Studio / VS Code.

Koneksi Internet (untuk download package pertama kali).

Langkah-Langkah:

Clone / Copy Folder Proyek
Simpan folder my_gadget di komputermu.

Buka Terminal di Folder Proyek
Jalankan perintah ini untuk membersihkan cache lama:

flutter clean


Download Dependensi
Jalankan perintah ini untuk mengunduh semua library (http, provider, dll):

flutter pub get


Cek Konfigurasi Android (Penting!)
Pastikan file android/app/src/main/AndroidManifest.xml memiliki izin internet:

<uses-permission android:name="android.permission.INTERNET" />


Jalankan Aplikasi
Pastikan Emulator sudah nyala atau HP terhubung via USB.

flutter run


📝 6. Catatan Pengembangan (To-Do List)

Berikut adalah hal-hal yang bisa dikembangkan lebih lanjut oleh developer berikutnya:

[ ] Menambahkan fitur Edit Produk (Update).

[ ] Mengganti gambar dummy lokal dengan upload gambar asli.

[ ] Menambahkan format mata uang Rupiah yang lebih valid menggunakan package intl.

[ ] Menambahkan fitur Keranjang Belanja (Cart).

Dokumentasi ini dibuat sebagai laporan akhir praktikum Perancangan Aplikasi Mobile.


### **Saran Penggunaan:**
1.  **Simpan Kode di Atas:** Kamu bisa menyimpan teks di atas menjadi file bernama **`README.md`** di dalam folder project-mu. Ini adalah standar internasional dokumentasi software.
2.  **Untuk Laporan Kuliah:** Kamu bisa copy-paste isinya ke Microsoft Word, lalu tambahkan screenshot aplikasimu di bagian-bagian yang relevan.

Ini akan membuat project-mu terlihat sangat profesional dan siap diserahterimakan! 🌟
