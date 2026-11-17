# Padi Scan

Aplikasi identifikasi penyakit daun padi berbasis citra menggunakan
MobileNetV2 dan rekomendasi penanganan.

Tugas Akhir — Arnanda Setya Nosa Putra (2311102180)
Program Studi Sarjana Teknik Informatika, Universitas Telkom Direktorat Kampus Purwokerto.

Kode ini mengimplementasikan Bab III proposal
(`Proposal_TA_Arnanda_Padi_v14.docx`): metode Waterfall, kebutuhan fungsional
F-01 s.d. F-08, kebutuhan nonfungsional NF-01 s.d. NF-05, arsitektur tiga lapis,
basis data SQLite, dan mesin aturan R1–R5.

## Status saat ini

| Bagian | Status |
|---|---|
| Struktur project + dependensi | selesai |
| Basis data SQLite + seed data penyakit | selesai |
| Mesin aturan R1–R5 (ambang 70%) | selesai |
| Prapemrosesan citra (224x224, 1/255) | selesai |
| Lapisan TFLite | selesai (butuh berkas model) |
| UI: beranda, hasil, rekomendasi, riwayat, info | selesai |
| Berkas model `.tflite` | **belum ada — lihat langkah di bawah** |
| `flutter pub get` | **belum dijalankan (butuh jaringan)** |

> [!IMPORTANT]
> Aplikasi dapat dibuka dan diuji tanpa berkas model, tetapi tombol
> identifikasi akan menampilkan pesan bahwa model belum tersedia.
> Untuk mengaktifkan F-03, letakkan berkas model sesuai langkah 2.

## Langkah menjalankan

### 1. Ambil dependensi (butuh internet, sekali saja)

```powershell
cd "D:\TUGAS AKHIR\aplikasi TA"
flutter pub get
```

### 2. Letakkan berkas model TensorFlow Lite

Salin berkas model hasil penelitian Mustofa dkk. (2026) ke:

```
assets/models/padi_mobilenetv2.tflite
```

Bila berkas dari penulis tidak tersedia, replikasi pelatihan dengan
`replikasi_mustofa2026.py` (di folder induk), lalu konversi ke TFLite:

```python
import tensorflow as tf
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
open("padi_mobilenetv2.tflite", "wb").write(converter.convert())
```

Pindahkan hasilnya ke `assets/models/padi_mobilenetv2.tflite`.

> [!WARNING]
> Urutan label di `assets/models/labels.txt` harus sama dengan urutan kelas
> keluaran model. Urutan default mengikuti kelas alfabetis dataset
> "Data Rice Leaf FN": `bercak_cokelat`, `blas`, `hawar_daun_bakteri`, `normal`.
> Periksa dengan `print(train_it.class_indices)` pada skrip replikasi dan
> sesuaikan `labels.txt` bila berbeda. Urutan yang salah membuat aplikasi
> menampilkan nama penyakit yang keliru meski model akurat.

### 3. Jalankan aplikasi

```powershell
flutter devices
flutter run
```

### 4. Bangun APK

```powershell
flutter build apk --release
```

APK dihasilkan di `build/app/outputs/flutter-apk/app-release.apk`.
Ukuran berkas APK ini dicatat untuk pengujian kinerja (subbab 3.5 huruf b).

## Struktur folder

```
lib/
  main.dart                     titik masuk aplikasi
  theme/app_theme.dart          tema dan tipografi (NF-04)
  models/
    penyakit.dart               model penyakit + rekomendasi
    hasil_identifikasi.dart     hasil identifikasi, probabilitas, riwayat
  data/database_helper.dart     SQLite: penyakit, rekomendasi, riwayat
  logic/
    image_preprocessor.dart     resize 224x224 + rescale 1/255
    tflite_classifier.dart      inferensi TFLite + pengukuran waktu
    rule_engine.dart            aturan R1-R5, ambang 70%
  screens/
    home_screen.dart            F-01, F-02
    hasil_screen.dart           F-04, F-06
    rekomendasi_screen.dart     F-05
    riwayat_screen.dart         F-07
    detail_riwayat_screen.dart  detail entri riwayat
    informasi_screen.dart       F-08
assets/
  models/padi_mobilenetv2.tflite   model (belum tersedia)
  models/labels.txt                urutan kelas keluaran model
  data/penyakit.json               seed penyakit + rekomendasi (Tabel 2.2)
test/
  rule_engine_test.dart         pengujian unit aturan R1-R5
```

## Pemetaan kebutuhan ke kode

| Kode | Wujud di kode |
|---|---|
| F-01 | `home_screen.dart` → `ImageSource.camera` |
| F-02 | `home_screen.dart` → `ImageSource.gallery` |
| F-03 | `tflite_classifier.dart` (inferensi di perangkat, tanpa jaringan) |
| F-04 | `hasil_screen.dart` → `_KartuHasil` (nama + keyakinan) |
| F-05 | `rekomendasi_screen.dart` |
| F-06 | `rule_engine.dart` aturan R5 + `_KartuTidakDikenali` |
| F-07 | `riwayat_screen.dart`, `detail_riwayat_screen.dart` |
| F-08 | `informasi_screen.dart` |
| NF-01 | tidak ada dependensi jaringan; model dan data arsip lokal |
| NF-02 | `waktuInferensiMs` diukur dan ditampilkan di halaman hasil |
| NF-03 | `minSdk = 26` pada `android/app/build.gradle.kts` |
| NF-04 | `app_theme.dart`, seluruh teks berbahasa Indonesia |
| NF-05 | `assets/data/penyakit.json` hanya bahan aktif tanpa merek/dosis |

## Catatan untuk BAB IV

Nilai yang perlu dicatat saat pengujian:

- **Waktu inferensi**: lihat "Waktu inferensi" di halaman hasil, atau pakai
  `TfliteClassifier.rataRataMs` dan `persentilMs` untuk menghitung rata-rata
  dan persentil ke-95 dari 30 citra per perangkat.
- **Ukuran APK**: dari `build/app/outputs/flutter-apk/app-release.apk`.
- **Akurasi model terintegrasi**: jalankan `identifikasiBatch` pada 928 citra
  uji lalu bandingkan `idPenyakit` hasil prediksi dengan label sebenarnya
  untuk menyusun confusion matrix.
- **Nilai ambang batas**: ubah `RuleEngine.ambangKeyakinan` (satu tempat saja)
  bila hasil pengujian menunjukkan ambang 70% perlu disesuaikan.

## Asumsi yang perlu dicatat di laporan

- Interpolasi pengubahan ukuran citra memakai bilinear (`Interpolation.linear`),
  sesuai perilaku bawaan `ImageDataGenerator`.
- Model diasumsikan menerima tensor `[1, 224, 224, 3]` dengan nilai 0–1 dan
  mengeluarkan `[1, 4]` probabilitas softmax. Bila berkas model memakai
  preprocessing berbeda (misalnya MobileNetV2 `preprocess_input` dengan
  rentang -1..1), sesuaikan `image_preprocessor.dart`.
# Padi Scan 2.0

Aplikasi Flutter untuk identifikasi empat kelas kondisi daun padi memakai MobileNetV2/TFLite sepenuhnya offline. Versi 2.0 menambah pratinjau dan pemeriksaan kualitas foto, audit hasil, catatan petak/musim/survei, timeline, ekspor CSV v2, dan navigasi responsif.

Dokumen utama:

- `docs/PRD-PADI-SCAN-2.0.md`
- `docs/UI-REDESIGN-PADI-SCAN-2.0.md`
- `docs/IMPLEMENTATION-PADI-SCAN-2.0.md`
- `assets/models/model_manifest.json`

Peringatan penelitian: model di aplikasi adalah reimplementasi lokal, bukan bobot asli penulis jurnal. Detail split, metrik, hash artefak, dan `[ASUMSI]` tercatat di manifest.

