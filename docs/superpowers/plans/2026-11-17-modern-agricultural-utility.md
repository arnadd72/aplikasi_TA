# Modern Agricultural Utility Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Merombak total desain dan fitur aplikasi Padi Scan mengikuti spesifikasi PRD *Modern Agricultural Utility / Clean Agricultural Utility* (S-01 s.d. S-18, F-01 s.d. F-27) dengan tetap mematuhi batasan penelitian (NF-01..NF-05, R1–R5, ambang 70%, model MobileNetV2 TFLite).

**Architecture:** Arsitektur modular *offline-first* berbasis Flutter + SQLite v3 (*expand-only migration*) + TensorFlow Lite (`tflite_flutter 0.12.1`). Navigasi utama menggunakan 4 tab (`Beranda`, `Lahan Saya`, `Riwayat`, `Panduan`) dengan ikon `Pengaturan` di bilah atas `Beranda` serta alur `SplashScreen` → `OnboardingScreen` → `AppShell`.

**Tech Stack:** Flutter, Dart, `sqflite`, `tflite_flutter`, `image_picker`, `image`, `share_plus`.

**Spec:** `docs/PRD-PADI-SCAN-2.0.md` & PRD v1.0 *Modern Agricultural Utility*

## Global Constraints

- Identifikasi berjalan **sepenuhnya offline** (NF-01 / NFR-01).
- Rekomendasi hanya menampilkan **bahan aktif**, tanpa merek dagang dan tanpa dosis otomatis (NF-05 / F-08).
- Minimum Android 8.0 / API 26 (NF-03 / NFR-06).
- Antarmuka berbahasa Indonesia (NF-04).
- Waktu inferensi $< 1$ detik di perangkat (NF-02 / NFR-02).
- Ambang keyakinan 70% dengan aturan R1–R5; di bawah 70% menampilkan: `"Hasil belum cukup meyakinkan. Coba ambil foto daun yang lebih jelas."`
- Palet warna utama PRD Section 9.1: Primary `#176B4D`, Primary Dark `#123D32`, Background `#F7F8F4`, Surface `#FFFFFF`, Border `#E0E6DF`, Text Primary `#17251E`, Text Secondary `#627168`, Warning `#A76516`, Danger `#B42318`, Accent `#DCE9BD`.

## Review Focus

1. Migrasi basis data SQLite dari v1/v2 ke v3 tidak boleh merusak data riwayat atau petak yang sudah ada (*expand-only migration*).
2. Umur tanaman (HST) dihitung deterministik dari `tanggalTanam`; jika `tanggalTanam == null`, umur tanaman tidak ditampilkan dan diganti tombol mengisi tanggal tanam (PRD F-12 / S-12).
3. Penghapusan lahan meminta konfirmasi dan melepas relasi `id_petak` pada riwayat tanpa menghapus riwayat pemeriksaan (PRD F-11).
4. Halaman hasil (`HasilScreen`) menonjolkan nama penyakit sebagai elemen utama, menempatkan skor sebagai informasi sekunder, dan menyembunyikan rincian skor ke-4 kelas di dalam accordion agar tidak membingungkan petani (PRD F-07 / S-07).
5. Kontras warna pada tema terang maupun gelap wajib $\ge 4,5:1$ dan seluruh target sentuh utama $\ge 48 \times 48$ dp (PRD Section 9.1 / NFR-08).

---

### Task 1: Design System Tokens & Theme (`Clean Agricultural Utility`)
- [x] Update `lib/theme/app_tokens.dart` dan `lib/theme/app_theme.dart` sesuai palet PRD Section 9.1 (`#176B4D`, `#123D32`, `#F7F8F4`, `#FFFFFF`, `#E0E6DF`, `#17251E`, `#627168`, `#A76516`, `#B42318`, `#DCE9BD`), skala tipografi (`26/22/18/16/14/12-13sp`), padding horizontal `20dp`, radius kartu `16dp`, radius tombol `12dp`, tinggi tombol `54dp`.
- [x] Update `design-system/padi-scan/OVERRIDES.md` untuk mencatat palet & tipografi PRD *Modern Agricultural Utility*.

### Task 2: Database v3, Domain Entities & Knowledge Base (`F-08`..`F-16`, `F-24`, `F-25`)
- [x] Perluas `assets/data/penyakit.json` dan `lib/models/penyakit.dart` dengan foto asli (`assets/images/*.jpg`), penjelasan singkat, faktor pendukung, langkah pengamatan lanjutan, pencegahan, dan tanggal peninjauan.
- [x] Perluas `lib/models/catatan_lapangan.dart`, `lib/models/hasil_identifikasi.dart`, `lib/data/database_helper.dart`, dan `lib/data/catatan_lapangan_repository.dart` ke SQLite v3:
  - Lahan (`petak`): dukung edit/hapus lahan, `satuan_luas` (`ha`, `m²`, `bahu`, `patok`), `catatan`, perhitungan `umurHariSetelahTanam`.
  - Riwayat (`riwayat`): dukung `catatan_pengguna`, `status_penanganan`, update lahan & catatan.
  - Catatan Pengamatan (`pengamatan`): tambah, edit, hapus catatan pengamatan manual terkait lahan & riwayat.
  - Jadwal Perawatan (`jadwal_perawatan`): tambah, tandai selesai, hapus jadwal kegiatan lahan.
- [x] Perluas `lib/data/pengaturan.dart` untuk menyimpan status `onboardingSelesai` dan daftar `bookmarkPenyakit`.

### Task 3: Splash, Onboarding, AppShell & Beranda (`S-01`..`S-03`, `F-01`, `F-02`)
- [x] Buat `lib/screens/splash_screen.dart` (`S-01`) dan `lib/screens/onboarding_screen.dart` (`S-02`, 3 halaman dengan foto tanaman padi asli + tombol `Lewati` / `Mulai`).
- [x] Perbarui `lib/screens/app_shell.dart` menjadi 4 tab: `Beranda`, `Lahan Saya`, `Riwayat`, `Panduan`.
- [x] Rombak `lib/screens/home_screen.dart` (`S-03`): sapaan `"Selamat datang"`, subteks `"Pantau kesehatan tanaman padi Anda."`, status offline & ikon Pengaturan di atas, kartu utama `"Periksa Kesehatan Daun Padi"` + tombol `"Identifikasi Sekarang"`, kartu Lahan Aktif (atau ajakan tambah lahan), Identifikasi Terakhir, Pengamatan Terbaru, Jadwal Perawatan Terdekat, dan Pintasan Panduan Penyakit.

### Task 4: Alur Identifikasi, Pratinjau, Hasil & Rekomendasi (`S-04`..`S-08`, `F-03`..`F-08`)
- [x] Perbarui `lib/screens/photo_preview_screen.dart` (`S-05`: judul `"Periksa Foto"`, tombol `"Gunakan Foto"` & `"Ambil Ulang"`, panduan `"Pastikan daun terlihat jelas dan tidak buram."`).
- [x] Rombak `lib/screens/hasil_screen.dart` (`S-07`: header `"Hasil Pemeriksaan"`, label utama `"Kemungkinan: <Penyakit>"` / `"Hasil belum cukup meyakinkan. Coba ambil foto daun yang lebih jelas."`, skor sekunder, daftar gejala umum, pilihan simpan ke lahan + catatan, accordion rincian skor & teknis, tombol `"Lihat Penanganan"`, `"Simpan Hasil"`, `"Periksa Lagi"`).
- [x] Rombak `lib/screens/rekomendasi_screen.dart` (`S-08`: foto penyakit asli, ringkasan, accordion gejala & pengamatan lanjutan, pencegahan & kultur teknis, pengendalian hayati, informasi bahan aktif kimia, referensi & tanggal peninjauan).

### Task 5: Lahan Saya, Detail Lahan, Pengamatan, Jadwal & Perbandingan Foto (`S-10`..`S-13`, `S-16`, `S-17`)
- [x] Rombak `lib/screens/petak_screen.dart` (`S-10`: `"Lahan Saya"`, kartu lahan dengan varietas, luas + satuan, tanggal tanam & HST, pemeriksaan terbaru).
- [x] Perbarui `lib/screens/form_petak_screen.dart` (`S-11`: tambah & edit lahan, pilihan satuan luas, catatan).
- [x] Rombak `lib/screens/timeline_petak_screen.dart` (`S-12`, `S-13`, `S-16`, `S-17`: Detail Lahan lengkap dengan metadata & HST, tombol `"Tambah Pemeriksaan"`, `"Tambah Pengamatan"`, `"Tambah Jadwal"`, daftar catatan pengamatan manual, jadwal perawatan, kronologi riwayat, dan dialog **Perbandingan Foto Sebelum/Sesudah**).

### Task 6: Riwayat, Pustaka Penyakit & Pengaturan (`S-09`, `S-14`, `S-15`, `S-18`)
- [x] Rombak `lib/screens/riwayat_screen.dart` (`S-09`: filter penyakit + filter lahan, pencarian, kartu riwayat menampilkan nama lahan, empty state `"Belum ada hasil pemeriksaan."` + tombol `"Identifikasi Penyakit"`) dan `lib/screens/detail_riwayat_screen.dart` (edit catatan & lahan, perbandingan foto).
- [x] Rombak `lib/screens/informasi_screen.dart` (`S-14` & `S-15`: `"Panduan Penyakit"`, pencarian, filter bookmark, kartu penyakit dengan foto gejala asli, halaman detail penyakit lengkap, serta artikel edukasi budidaya & panduan foto).
- [x] Rombak `lib/screens/pengaturan_screen.dart` (`S-18`: kelompok menu **Aplikasi**, **Data**, dan **Informasi**).

### Task 7: Pengujian, Verifikasi & Build APK
- [x] Perbarui dan tambahkan pengujian unit & widget di `test/` untuk seluruh fitur PRD.
- [x] Jalankan `flutter analyze`, `flutter test`, `flutter build apk --debug`, dan `flutter build apk --release`.
