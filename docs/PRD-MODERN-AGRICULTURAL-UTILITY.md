# PRODUCT REQUIREMENTS DOCUMENT (PRD) — Implementasi Padi Scan
## Aplikasi Identifikasi Penyakit Daun Padi Berbasis Mobile

**Versi:** 1.0 (Diterapkan Penuh)  
**Platform:** Android (minSdk 26 / Android 8.0+)  
**Teknologi utama:** Flutter, Dart, TensorFlow Lite (`tflite_flutter 0.12.1` / LiteRT 1.4.0), MobileNetV2, SQLite (`sqflite`)  
**Metode pengembangan:** V-Model  
**Konsep desain:** Modern Agricultural Utility / Clean Agricultural Utility  
**Target pengguna:** Petani padi dan penyuluh pertanian  
**Strategi produk:** Offline-first

---

## Pemetaan Implementasi Kode terhadap Spesifikasi PRD

| Kode PRD | Fitur / Layar | Berkas Implementasi | Status |
|---|---|---|---|
| **S-01** | Splash Screen & pemeriksaan kesiapan model/DB | `lib/screens/splash_screen.dart` | Selesai |
| **F-01 / S-02** | Onboarding 3 halaman dengan foto tanaman padi asli | `lib/screens/onboarding_screen.dart`, `lib/data/pengaturan.dart` | Selesai |
| **F-02 / S-03** | Beranda (Sapaan, Status Offline, Pengaturan, Kartu Identifikasi Sekarang, Lahan Aktif, Identifikasi Terakhir, Pengamatan Terbaru, Jadwal Terdekat, Pintasan Panduan) | `lib/screens/home_screen.dart`, `lib/screens/app_shell.dart` | Selesai |
| **F-03 / F-04 / S-04 / S-05** | Kamera & Galeri + Pratinjau Foto dengan bingkai panduan & pemeriksaan kualitas | `lib/screens/photo_preview_screen.dart`, `lib/logic/photo_quality_checker.dart` | Selesai |
| **F-05 / F-06 / S-06** | Prapemrosesan (224x224, RGB 0–1) & Inferensi MobileNetV2 TFLite Offline (`C01..C04`, R1–R5, ambang 70%) | `lib/logic/image_preprocessor.dart`, `lib/logic/tflite_classifier.dart`, `lib/logic/rule_engine.dart` | Selesai |
| **F-07 / S-07** | Halaman Hasil Pemeriksaan (Nama penyakit menonjol, skor sekunder, gejala umum, simpan ke lahan & catatan, ketidakpastian $<70\%$) | `lib/screens/hasil_screen.dart` | Selesai |
| **F-08 / S-08** | Rekomendasi Penanganan 10 struktur informasi + accordion (kultur teknis, hayati, kimia bahan aktif tanpa merek/dosis, sumber & tanggal tinjau) | `lib/screens/rekomendasi_screen.dart`, `assets/data/penyakit.json` | Selesai |
| **F-09 / F-20 / S-09** | Riwayat Identifikasi (Pencarian, filter penyakit, filter lahan, detail riwayat, catatan & status penanganan) | `lib/screens/riwayat_screen.dart`, `lib/screens/detail_riwayat_screen.dart` | Selesai |
| **F-10 / F-21 / F-24 / F-25 / S-14 / S-15** | Pustaka Penyakit (`C01..C04`) dengan foto gejala asli, pencarian, bookmark panduan, detail penyakit, dan artikel edukasi budidaya | `lib/screens/informasi_screen.dart`, `assets/images/*.jpg` | Selesai |
| **F-11 / F-12 / S-10 / S-11 / S-12** | Pengelolaan Lahan Dasar & Detail Lahan (Tambah, Edit, Hapus aman, satuan luas `ha`/`m²`/`bahu`/`patok`, perhitungan umur tanaman HST deterministik) | `lib/screens/petak_screen.dart`, `lib/screens/form_petak_screen.dart`, `lib/screens/timeline_petak_screen.dart` | Selesai |
| **F-13 / S-13** | Catatan Pengamatan Manual (Tambah, Edit, Hapus, kronologi lahan) | `lib/models/catatan_lapangan.dart`, `lib/screens/timeline_petak_screen.dart` | Selesai |
| **F-14** | Penyimpanan Lokal SQLite v5 (*expand-only*, transaksi atomik, foreign keys) | `lib/data/database_helper.dart` | Selesai |
| **F-15 / F-22 / F-23 / S-18** | Pengaturan Dasar (Kelompok Aplikasi, Data, Informasi) + Ekspor CSV & Bagikan Laporan Penyuluh | `lib/screens/pengaturan_screen.dart`, `lib/utils/riwayat_exporter.dart` | Selesai |
| **F-16 / S-16** | Jadwal Perawatan Lahan (6 jenis kegiatan awal, tandai selesai, hapus) | `lib/models/catatan_lapangan.dart`, `lib/screens/timeline_petak_screen.dart` | Selesai |
| **F-18 / F-19 / S-17** | Monitoring Perkembangan & Perbandingan Foto Sebelum/Sesudah | `lib/screens/timeline_petak_screen.dart` | Selesai |

---

## Sistem Desain (PRD Bagian 9.1 — Clean Agricultural Utility)

- **Primary:** `#176B4D`
- **Primary Dark:** `#123D32`
- **Background:** `#F7F8F4`
- **Surface / Card:** `#FFFFFF`
- **Border:** `#E0E6DF`
- **Text Primary:** `#17251E`
- **Text Secondary:** `#56655C` (`#627168` PRD, dioptimalkan untuk kontras WCAG $\ge 4,5:1$)
- **Warning:** `#A76516`
- **Danger:** `#B42318`
- **Accent:** `#DCE9BD`
- **Tipografi:** Heading utama `26sp` Semibold, Heading halaman `22sp` Semibold, Judul section `18sp` Semibold, Judul kartu `16sp` Semibold, Body `16sp` Regular, Teks pendukung `14sp` Regular, Caption `12–13sp` Medium, Tombol utama `16sp` Semibold.
- **Layout:** Padding horizontal `20dp`, Spacing kecil `8dp`, sedang `12–16dp`, section `24dp`, Radius kartu `16dp`, Radius tombol `12dp`, Tinggi tombol utama `54dp` (`52–56dp`), Minimum touch target `48 × 48dp`.
