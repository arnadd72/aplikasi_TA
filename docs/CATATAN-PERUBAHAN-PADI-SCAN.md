# Catatan Perubahan & Serah-Terima — Padi Scan

**Terakhir diperbarui:** 16 November 2026, 10:15 WIB
**Status:** **BLOKIR #1 SUDAH DIPERBAIKI & TERVERIFIKASI DI HP.** Model dimuat, F-03..F-06 hidup. Palet diubah ke "Soft Sage" atas permintaan pengguna.

## 0B. PERUBAHAN PALET — "SOFT SAGE"

Permintaan pengguna: warna/UI dibuat lebih lembut, tidak terlalu hijau.

**Dokumen rinci:** [PALET-SOFT-SAGE.md](file:///D:/TUGAS%20AKHIR/aplikasi%20TA/design-system/padi-scan/PALET-SOFT-SAGE.md)

| | Lama | **Baru** |
|---|---|---|
| Primer terang | `#15803D` (hijau pekat) | **`#4F7157`** (sage) |
| Latar terang | `#F0FDF4` (mint) | **`#F7F5F0`** (krem hangat) |
| Primer gelap | `#4ADE80` (hijau menyala) | **`#9DBFA3`** |
| Latar gelap | `#08170F` (hijau-hitam) | **`#1A1C19`** (arang hangat) |
| Kartu gelap | `#10241A` | **`#242723`** |

**Verifikasi di HP** (analisis warna tangkapan layar 1080x2400):
`#242723` 59,75 % · `#1A1C19` 21,09 % · `#9DBFA3` 5,42 % — palet gelap aktif, tidak ada hijau menyala.

**Kontras WCAG:** seluruh 22 pasangan lulus >= 4,5:1 (teks) dan >= 3:1 (non-teks). Paling mepet `onSecondary/secondary` = 4,54 (terang). Pengukur: `D:\TUGAS AKHIR\ml\cek_kontras.py`.

**Berkas disentuh:** `lib/theme/app_tokens.dart` (2 palet), `lib/theme/app_theme.dart` (16 slot ColorScheme + SnackBar). Tidak ada widget diubah — semua layar sudah memakai token.

## 0A. PERBAIKAN BLOKIR — SUDAH DITERAPKAN

**Pilihan A dipilih dan dikerjakan.**

| Langkah | Hasil |
|---|---|
| `pubspec.yaml`: `tflite_flutter: ^0.11.0` → `^0.12.1` | diterapkan |
| `flutter pub get` | `> tflite_flutter 0.12.1 (was 0.11.0)` — sukses |
| `flutter analyze` | `No issues found! (ran in 34.3s)` |
| `flutter build apk --debug` | `Built build\app\outputs\flutter-apk\app-debug.apk` (196.682.500 B, 83,1 s) |
| `adb install -r` | `Success` |
| Logcat | **`I tflite : Initialized TensorFlow Lite runtime.`** + **`[TFLite] model dimuat. input=[1, 224, 224, 3] output=[1, 4]`** — BERHASIL |

**Bukti pemilihan:**
- `tflite_flutter` 0.12.1 menarik `com.google.ai.edge.litert:litert:1.4.0`.
- `litert-1.4.0.aar` memuat `jni/<abi>/libtensorflowlite_jni.so` — **nama sama** dengan yang dibuka `bindings.dart` di v0.12.1, jadi tidak perlu bungkus ulang binding.
- LiteRT 2.3.2 memakai `libLiteRt.so` (nama berbeda) → tidak kompatibel tanpa penyesuaian; tidak dipakai.

Artefak pendukung: `D:\TUGAS AKHIR\ml\_aar\litert-1.4.0.aar`, `litert-2.3.2.aar`, `D:\TUGAS AKHIR\ml\_aar\tflite0121\tf.tar.gz` (sumber 0.12.1, sudah diekstrak ke `D:\TUGAS AKHIR\_ext`).

---

## 0. BLOKIR LAMA (RIWAYAT — sudah diperbaiki)

> [!CAUTION]
> **Model TFLite GAGAL dimuat di HP.** Aplikasi terbuka dan seluruh layar berjalan, tetapi F-03..F-06 mati karena interpreter tidak dapat dibuat. Ini satu-satunya pekerjaan yang belum tuntas dari sesi terakhir. Mulai dari sini.

### 0.1 Gejala persis

Logcat dari HP (`adb logcat -d | Select-String tflite`):

```
E tflite  : Didn't find op for builtin opcode 'FULLY_CONNECTED' version '12'. An older
version of this builtin might be supported. Are you using an old TFLite binary with a newer model?
E tflite  : Registration failed.
I flutter : [TFLite] gagal memuat model: Invalid argument(s): Unable to create interpreter.
```

### 0.2 Sebab

TF 2.21.0 memakai `FULLY_CONNECTED` **versi 12** saat mengonversi model. Runtime TFLite yang dipaketkan aplikasi berasal dari paket `tflite_flutter` **0.11.0**, yang menarik `org.tensorflow:tensorflow-lite:2.11.0` (lihat `android/build.gradle` di dalam paket itu). Runtime 2.11.0 terlalu tua untuk op versi 12.

Berkas yang relevan:

| Berkas | Isi penting |
|---|---|
| `C:\Users\hp_5c\AppData\Local\Pub\Cache\hosted\pub.dev\tflite_flutter-0.11.0\android\build.gradle` | `def tflite_version = "2.11.0"` — **sumber masalah** |
| `...\tflite_flutter-0.11.0\lib\src\bindings\bindings.dart` | Memuat `libtensorflowlite_jni.so` (Android) |
| `D:\TUGAS AKHIR\aplikasi TA\android\app\build.gradle.kts` | `minSdk = 26`, `abiFilters = armeabi-v7a, arm64-v8a, x86_64`, `noCompress += "tflite"` |

### 0.3 Fakta yang sudah diverifikasi

- Model **valid** — Python `tf.lite.Interpreter` memuatnya, `allocate_tensors()` sukses, `input [1 224 224 3]`, `output [1 4]`, 82 op.
- Isi op model: `ADD`, `CONV_2D`, `DEPTHWISE_CONV_2D`, `FULLY_CONNECTED`, `MEAN`, `SOFTMAX` (+ 16 `DELEGATE`).
- Runtime TFLite terbaru di Maven Central (`org.tensorflow:tensorflow-lite`) hanya sampai **2.17.0**. Paket penerusnya berpindah ke Google Maven: **`com.google.ai.edge.litert:litert`**, versi terakhir **2.3.2**.
- `litert-2.3.2.aar` sudah diunduh ke `D:\TUGAS AKHIR\ml\_aar\litert-2.3.2.aar` (7.640.090 byte). Isinya memakai nama pustaka **`libLiteRt.so`** (bukan `libtensorflowlite_jni.so`), dengan `classes.jar` terpisah:

```
AndroidManifest.xml               823
classes.jar                     25390
jni/arm64-v8a/libLiteRt.so    5629696
jni/armeabi-v7a/libLiteRt.so  3653808
jni/x86_64/libLiteRt.so       7784496
```

> [!WARNING]
> Karena nama pustaka berubah (`libLiteRt.so` vs `libtensorflowlite_jni.so`), memang menaikkan versi dependensi gradle saja **tidak cukup**. `bindings.dart` di dalam `tflite_flutter` memanggil `DynamicLibrary.open('libtensorflowlite_jni.so')` secara hard-code.

- `tflite_flutter` versi terbaru di pub.dev adalah **0.12.1** (terpasang sekarang: 0.11.0). Unduhan `0.12.1` sedang dilakukan ke `D:\TUGAS AKHIR\ml\_aar\tflite0121\tf.tar.gz`; periksa apakah versi itu sudah memakai `libLiteRt.so`.
- AAR `org.tensorflow:tensorflow-lite:2.17.0` **tidak ada** di Maven Central (404 pada `.aar`), jadi jalur naik-versi `org.tensorflow` tidak tersedia.

### 0.4 Pilihan perbaikan (pilih satu, urut dari paling murah)

**Pilihan A — naikkan `tflite_flutter` ke 0.12.1.** Paling murah. Periksa `D:\TUGAS AKHIR\ml\_aar\tflite0121\tf.tar.gz`; bila `lib/src/bindings/bindings.dart` di dalamnya sudah memuat `libLiteRt.so`, cukup:

```powershell
cd "D:\TUGAS AKHIR\aplikasi TA"
# ubah pubspec.yaml: tflite_flutter: ^0.12.1
& "D:\flutter\flutter\bin\flutter.bat" pub get
& "D:\flutter\flutter\bin\flutter.bat" build apk --debug
& "D:\android_sdk\platform-tools\adb.exe" install -r "D:\TUGAS AKHIR\aplikasi TA\build\app\outputs\flutter-apk\app-debug.apk"
```

**Pilihan B — paksa versi runtime lebih baru lewat `android/app/build.gradle.kts`.** Tambahkan di blok `dependencies` supaya Gradle menaikkan/menimpa versi bawaan plugin:

```kotlin
dependencies {
    implementation("com.google.ai.edge.litert:litert:2.3.2")
}
```

Bila `tflite_flutter` masih memanggil `libtensorflowlite_jni.so`, pustaka `libLiteRt.so` tidak akan ditemukan. Perlu salah satu: (a) salin `jni/<abi>/libLiteRt.so` menjadi `libtensorflowlite_jni.so` di `src/main/jniLibs/`, atau (b) bungkus ulang binding. Periksa dulu versi A.

**Pilihan C — konversi ulang model tanpa op versi 12.** Jalankan konversi TFLite dengan `converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS]` dan bangun ulang dari `best.keras` memakai `ml/convert_tflite.py`. Cara ini menurunkan versi op bila TF mengizinkannya, tetapi **tidak dijamin** dan mengubah artefak model. Bila ditempuh, catat sebagai penyimpangan tambahan di Bagian 6.5.

**Pilihan D — turunkan versi TensorFlow pelatihan.** Latih ulang dengan TF <= 2.15 yang op `FULLY_CONNECTED`-nya masih versi lama. Paling mahal (latih ulang 49 menit), dan bertentangan dengan semangat "tidak mengubah algoritma".

> [!TIP]
> Urutan yang disarankan: **A dulu**, lalu **B**, lalu **C/D** hanya bila dua yang pertama gagal.

### 0.5 Cara memverifikasi sudah beres

```powershell
& "D:\android_sdk\platform-tools\adb.exe" logcat -c
& "D:\android_sdk\platform-tools\adb.exe" shell am force-stop id.ac.telkomuniversity.padi_scan
& "D:\android_sdk\platform-tools\adb.exe" shell am start -n id.ac.telkomuniversity.padi_scan/.MainActivity
Start-Sleep -Seconds 10
& "D:\android_sdk\platform-tools\adb.exe" logcat -d -s flutter:I | Select-Object -Last 40
```

**Berhasil** bila muncul:

```
[TFLite] model dimuat. input=[1 224 224 3] output=[1 4]
```

**Gagal** bila masih muncul `Unable to create interpreter` atau `Didn't find op for builtin opcode`.

### 0.6 Yang sudah DIVERIFIKASI BEKERJA di HP

- APK `app-debug.apk` terpasang bersih (`adb install -r` → `Success`).
- Aplikasi terbuka; Impeller/Vulkan aktif; tidak ada galat render.
- **`flutter test` → 49 uji lulus.** `flutter analyze` → `No issues found!`
- Model `assets/models/padi_mobilenetv2.tflite` (2.847.440 byte) ikut masuk APK.

---

## 1. Ringkasan Proyek

| Item | Nilai |
|---|---|
| Judul skripsi | Sistem Identifikasi Penyakit Daun Padi Berbasis Mobile |
| Penulis | Arnanda |
| Penelitian terdahulu yang direplikasi | Mustofa, Arifin & Zulfia (2026), *JAIC* 10(2):1896–1904 |
| DOI | 10.30871/jaic.v10i2.12499 |
| Folder aplikasi Flutter | `D:\TUGAS AKHIR\aplikasi TA` |
| Nama paket Dart / Android | `padi_scan` / `id.ac.telkomuniversity.padi_scan` |
| Aktivitas utama | `.MainActivity` |
| Dataset | `D:\TUGAS AKHIR\dataset penelitian mustofa` — 6.180 citra JPEG, 4 kelas, 1.545 per kelas |
| Skrip latih | `D:\TUGAS AKHIR\ml\train_padi.py` |
| Skrip referensi asli | `D:\TUGAS AKHIR\replikasi_mustofa2026.py` |
| Jurnal | `D:\TUGAS AKHIR\jurnal mustofa.pdf` |

Kelas (4): `bercak_cokelat`, `blas`, `hawar_daun_bakteri`, `normal`
— padanan label model: `brown_spot`, `leaf_blast`, `leaf_blight`, `normal`.

---

## 2. Cara Melanjutkan (Perintah Persis)

### 2.1 Aturan penting

> [!CAUTION]
> Seluruh perintah `flutter` dan `adb` **harus dijalankan di luar sandbox**. Keduanya menulis ke `D:\flutter\flutter\bin\cache` dan `C:\Users\hp_5c\.android`, yang di luar cakupan sandbox.

- PowerShell memerlukan `&` sebelum path exe yang dikutip.
- `flutter` dan `adb` selalu jalankan dari direktori kerja masing-masing.
- Latih model: prosesor saja (CPU). TensorFlow di Windows asli tidak memakai GPU untuk versi >= 2.11.

### 2.2 Perintah harian

```powershell
# Alat
# adb     = "D:\android_sdk\platform-tools\adb.exe"
# flutter = "D:\flutter\flutter\bin\flutter.bat"
# python  = "D:\TUGAS AKHIR\ml\venv\Scripts\python.exe"

# --- Aplikasi Flutter ---
cd "D:\TUGAS AKHIR\aplikasi TA"
& "D:\flutter\flutter\bin\flutter.bat" pub get
& "D:\flutter\flutter\bin\flutter.bat" analyze
& "D:\flutter\flutter\bin\flutter.bat" test
& "D:\flutter\flutter\bin\flutter.bat" build apk --debug
& "D:\flutter\flutter\bin\flutter.bat" build apk --release

# --- Pasang ke HP ---
& "D:\android_sdk\platform-tools\adb.exe" devices
& "D:\android_sdk\platform-tools\adb.exe" install -r "D:\TUGAS AKHIR\aplikasi TA\build\app\outputs\flutter-apk\app-debug.apk"
& "D:\android_sdk\platform-tools\adb.exe" shell am start -n id.ac.telkomuniversity.padi_scan/.MainActivity

# --- Lihat bukti inferensi (NF-02) ---
& "D:\android_sdk\platform-tools\adb.exe" logcat -s flutter

# --- Ganti mode gelap/terang untuk uji ---
& "D:\android_sdk\platform-tools\adb.exe" shell cmd uimode night yes
& "D:\android_sdk\platform-tools\adb.exe" shell cmd uimode night no

# --- Latih ulang model (bila perlu) ---
cd "D:\TUGAS AKHIR\ml"
& ".\venv\Scripts\python.exe" train_padi.py --data "D:\TUGAS AKHIR\dataset penelitian mustofa" --out "D:\TUGAS AKHIR\ml\output" --epochs1 30 --epochs2 30 --batch 32 --seed 42
```

### 2.3 Lingkungan Python

| Komponen | Nilai |
|---|---|
| venv | `D:\TUGAS AKHIR\ml\venv` (basis Anaconda 3.12.7) |
| TensorFlow | 2.21.0 (CPU only) |
| Keras | 3.15.1 |
| scikit-learn | 1.9.1 |
| numpy | 2.5.4 |
| pillow | 13.0.0 |

> [!WARNING]
> Jangan memakai Python 3.13/3.14 untuk TensorFlow di mesin ini — tidak ada wheel yang cocok. Gunakan venv Anaconda 3.12 di atas. `conda.exe` yang dipanggil langsung mengalami *Illegal System DLL Relocation*; pakai `D:\Anaconda\python.exe -m conda` bila perlu.

---

## 3. Daftar Berkas yang Dibuat / Diubah

### 3.1 Lapisan tema & komponen (baru / ditulis ulang)

| Berkas | Ukuran | Isi |
|---|---|---|
| `lib/theme/app_tokens.dart` | 6.708 B | `AppSpacing`, `AppRadius`, `AppDurasi`, `AppIkon`, `kTargetSentuh = 48`; `AppPalet extends ThemeExtension` dengan `terang`/`gelap`; ekstensi `PaletKonteks` (`palet`, `teks`, `skema`, `warnaKeyakinan`) |
| `lib/theme/app_theme.dart` | 10.834 B | `abstract final class AppTheme`; `keluargaFont = 'PlusJakartaSans'`; ColorScheme M3 lengkap; 15 slot textTheme; tema komponen |
| `lib/widgets/komponen.dart` | 11.162 B | `KartuFoto`, `ImageFile`, `Lencana`, `KartuPesan`, `KepalaBagian`, `KeadaanKosong`, `BarisLabelNilai`, `KartuBagian` |
| `lib/utils/format_waktu.dart` | 1.562 B | `FormatWaktu.ringkas/angka/panjang/relatif`; nama bulan Indonesia; tanpa paket `intl` |
| `lib/data/pengaturan.dart` | 2.393 B | Penyimpanan pengaturan berbasis berkas JSON; `ValueNotifier<ThemeMode> modeTema`; `muat()`, `simpanModeTema()`, `labelMode()` |

### 3.2 Layar

| Berkas | Ukuran | Status | Isi |
|---|---|---|---|
| `lib/main.dart` | 1.056 B | ditulis ulang | `Future<void> main() async` + `await PengaturanStore.instance.muat()` + `ValueListenableBuilder<ThemeMode>` |
| `lib/screens/home_screen.dart` | 19.759 B | ditulis ulang | `RefreshIndicator` + `CustomScrollView`; bilah atas; tindakan utama (kamera/galeri + tombol Panduan); 4 kotak menu cepat; "Cara pakai"; catatan offline; lapisan memproses |
| `lib/screens/hasil_screen.dart` | 15.791 B | ditulis ulang | Hasil + grafik probabilitas 4 kelas; jalur tak-dikenali menampilkan panduan foto ulang |
| `lib/screens/rekomendasi_screen.dart` | 8.133 B | ditulis ulang | Daftar rekomendasi per kategori (kultur teknis; hayati & kimia) |
| `lib/screens/riwayat_screen.dart` | 15.545 B | ditulis ulang | Pencarian teks, chip filter kelas, menu urut, `KeadaanKosong` untuk tanpa hasil |
| `lib/screens/detail_riwayat_screen.dart` | 7.316 B | ditulis ulang | Rincian satu riwayat |
| `lib/screens/informasi_screen.dart` | 5.783 B | ditulis ulang | F-08 daftar 4 penyakit |
| `lib/screens/panduan_foto_screen.dart` | 4.673 B | **BARU** | 5 aturan pengambilan foto + 4 anti-pola (*Hindari*) |
| `lib/screens/statistik_screen.dart` | 11.090 B | **BARU** | Total/dikenali/tanpa-hasil/rata-rata; sebaran kelas; keyakinan tertinggi/terendah/rata-rata; waktu periksa terakhir |
| `lib/screens/pengaturan_screen.dart` | 10.772 B | **BARU** | Mode tema (Terang/Gelap/Sistem), Ekspor CSV, Salin Ringkasan, Hapus Semua, blok Tentang |

### 3.3 Konfigurasi & aset

| Berkas | Perubahan |
|---|---|
| `pubspec.yaml` | Blok `fonts` (PlusJakartaSans 400/500/600/700/800); dependensi `share_plus: ^10.1.4` |
| `assets/fonts/PlusJakartaSans-{Regular,Medium,SemiBold,Bold,ExtraBold}.ttf` | 5 berkas, ±129 KB per berkas, disimpan lokal agar NF-01 terpenuhi |
| `assets/models/padi_mobilenetv2.tflite` | **2.847.440 byte (2,72 MB)** — hasil latih penuh |
| `assets/models/labels.txt` | 496 B — urutan kelas sudah benar |
| `android/app/build.gradle.kts` | `minSdk = 26` (NF-03), `applicationId = "id.ac.telkomuniversity.padi_scan"` |

### 3.4 Pengujian

| Berkas | Jumlah uji | Isi |
|---|---|---|
| `test/format_waktu_test.dart` | 6 | Pemetaan bulan, format ringkas/angka/panjang/relatif |
| `test/tema_test.dart` | 15 | Kontras WCAG >= 4,5:1 untuk kedua palet; target sentuh >= 48 dp; ambang `warnaKeyakinan` |
| `test/rule_engine_test.dart` | 7 | R1–R5 dan batas tepat 70% (berkas lama, tidak diubah) |
| `test/home_screen_render_test.dart` | 3 | Regresi galat `BoxConstraints forces an infinite height` |
| `test/layar_render_test.dart` | 18 | 9 layar x 2 tema (terang & gelap) |

Hasil terakhir: **`flutter test` → 49 uji lulus** (6 format_waktu + 15 tema + 7 rule_engine + 3 beranda + 18 layar).

### 3.5 Sistem desain

| Berkas | Isi |
|---|---|
| `design-system/padi-scan/MASTER.md` | 234 baris — sumber kebenaran desain "Organic Biophilic" |
| `design-system/padi-scan/OVERRIDES.md` | 5 penyimpangan terdokumentasi |

---

## 4. Fitur Aplikasi Saat Ini

### 4.1 Fitur dari Bab III

| Kode | Fitur | Status |
|---|---|---|
| F-01 | Ambil foto daun dengan kamera | ada |
| F-02 | Pilih foto dari galeri | ada |
| F-03 | Inferensi MobileNetV2 via TFLite | ada, model sudah tersedia |
| F-04 | Hasil identifikasi + probabilitas 4 kelas | ada |
| F-05 | Rekomendasi penanganan bahan aktif | ada |
| F-06 | Panduan foto ulang saat keyakinan < 70% | ada |
| F-07 | Riwayat identifikasi | ada, ditambah cari/filter/urut/hapus |
| F-08 | Informasi penyakit | ada |

### 4.2 Fitur tambahan (permintaan pengguna)

- **Panduan Ambil Foto** — 5 aturan + 4 anti-pola, dapat dibuka dari beranda.
- **Statistik** — ringkasan seluruh riwayat.
- **Pengaturan** — mode tema Terang/Gelap/Sistem, Ekspor Riwayat (CSV) via `Share.shareXFiles`, Salin Ringkasan ke papan klip, Hapus Semua Riwayat (dialog konfirmasi merusak).
- **Hitungan riwayat langsung** pada kotak menu "Riwayat" di beranda.
- **Tarik-untuk-menyegarkan** (pull-to-refresh) pada beranda.

---

## 5. Sistem Desain

Sumber: `design-system/padi-scan/MASTER.md` (gaya "Organic Biophilic").

### 5.1 Palet terang

| Peran | Hex |
|---|---|
| primary | `#15803D` |
| onPrimary | `#FFFFFF` |
| secondary | `#22C55E` |
| onSecondary | `#0F172A` |
| accent | `#A16207` |
| background | `#F0FDF4` |
| foreground | `#14532D` |
| card | `#FFFFFF` |
| muted | `#E8F0F1` |
| mutedForeground | `#475569` |
| border | `#BBF7D0` |
| destructive | `#DC2626` |

### 5.2 Palet gelap

| Peran | Hex |
|---|---|
| primary | `#4ADE80` |
| onPrimary | `#052E16` |
| secondary | `#22C55E` |
| onSecondary | `#052E16` |
| accent | `#FACC15` |
| onAccent | `#422006` |
| background | `#08170F` |
| foreground | `#DCFCE7` |
| card | `#10241A` |
| muted | `#1B3327` |
| mutedForeground | `#A7C4B4` |
| border | `#23503A` |
| destructive | `#F87171` |

### 5.3 Tipografi

Plus Jakarta Sans (bukan Fira Code + Fira Sans seperti di `MASTER.md` — lihat `OVERRIDES.md`). Bobot terdaftar: 400, 500, 600, 700, 800.

### 5.4 Aturan yang wajib dipatuhi widget

- Warna hanya dari token (`context.palet`), jangan hex ad-hoc di dalam widget.
- Ikon hanya dari Material vector. Tidak boleh emoji.
- `Semantics`/`ExcludeSemantics` wajib pada elemen interaktif.
- Target sentuh >= 48 dp melalui `kTargetSentuh`.
- Kontras >= 4,5:1, dijamin oleh `test/tema_test.dart`.

---

## 6. Status Model ML

### 6.1 Hasil latih penuh (16 November 2026)

| Metrik | Nilai | Pembanding paper |
|---|---|---|
| Splitting | train 4326 / val 927 / test 927 | paper 4324 / 928 / 928 |
| Fase 1 (head saja) | 19 epoch, 25,2 menit | — |
| Fase 2 (fine-tune 20 layer terakhir) | 19 epoch, 23,8 menit | — |
| Akurasi Keras (test) | **98,27 %** | 97,20 % |
| Akurasi TFLite (test) | **98,17 %** | — |
| Ukuran TFLite | **2,85 MB** (2.847.440 B) | 2,71 MB |
| Latensi (CPU mesin ini) | rata-rata 29,46 ms; median 28,09 ms; p95 37,14 ms | 144,80 ms (Intel i3 gen-10) |
| Vendorsklearn / TF | 1.9.1 / 2.21.0 | tidak disebut |

`val_accuracy` terbaik fase 2: **0,9838** (epoch 15 fase-2, epoch ke-35 global). Paper konvergen pada 0,9741 (epoch 25).

### 6.2 Laporan klasifikasi (test, 927 citra)

| Kelas | Precision | Recall | F1 | Support |
|---|---|---|---|---|
| brown_spot | 0,9912 | 0,9741 | 0,9826 | 232 |
| leaf_blast | 0,9696 | 0,9612 | 0,9654 | 232 |
| leaf_blight | 0,9706 | 0,9957 | 0,9830 | 232 |
| normal | 1,0000 | 1,0000 | 1,0000 | 231 |
| **macro avg** | **0,9828** | **0,9828** | **0,9827** | 927 |

### 6.3 Matriks konfusi

```
                 brown_spot  leaf_blast  leaf_blight  normal
brown_spot           226          6            0         0
leaf_blast             2        223            7         0
leaf_blight            0          1          231         0
normal                 0          0            0       231
```

### 6.4 Artefak di `D:\TUGAS AKHIR\ml\output\`

| Berkas | Ukuran |
|---|---|
| `best.keras` | 23.302.168 B |
| `padi_mobilenetv2.tflite` | 2.847.440 B |
| `metrics.json` | 7.741 B |
| `history.csv` | 4.590 B |
| `labels.json` | 68 B |
| `split_train.csv` / `split_val.csv` / `split_test.csv` | 418.815 / 90.046 / 89.921 B |

Model **sudah disalin otomatis** ke `D:\TUGAS AKHIR\aplikasi TA\assets\models\padi_mobilenetv2.tflite`.

### 6.5 Penyimpangan dari penelitian terdahulu — WAJIB dilaporkan di BAB III

| # | Penyimpangan | Sebab |
|---|---|---|
| 1 | Splitting 4326/927/927 vs paper 4324/928/928 | Pembulatan `sklearn.model_selection.train_test_split` berstratifikasi |
| 2 | `train_padi.py` menjalankan maksimum 30 + 30 = 60 epoch; paper maksimum 30 epoch total | Skrip dipecah dua fase terpisah, masing-masing dengan `EarlyStopping` sendiri. Dalam praktik berhenti di 19 + 19 |
| 3 | Skrip tidak memakai `class_weights` | Nilai akan 1,0000 karena dataset seimbang — tanpa efek |
| 4 | Pemartisian memakai DataFrame pandas, bukan `shutil.copy` seperti paper | Efisiensi; hasil split identik secara logika |
| 5 | `Optimize.DEFAULT` pada konversi TFLite | `[ASUMSI]` — paper tidak menyebut mode optimasi |
| 6 | `Dense(256, activation="relu")` pada head | `[ASUMSI]` — paper tidak menyebut fungsi aktivasi lapisan itu |
| 7 | Keras 3.15.1 / TF 2.21.0, CPU only | Paper memakai Google Colab (GPU). Tidak ada GPU TensorFlow di Windows asli |
| 8 | Replikasi mandiri karena berkas model paper tidak dipublikasikan | Diperlukan agar aplikasi memiliki model |

---

## 7. Riwayat Bug yang Sudah Diperbaiki

### 7.0 Model gagal dimuat di HP — `Didn't find op for builtin opcode 'FULLY_CONNECTED' version '12'` (BELUM DIPERBAIKI)

Lihat **Bagian 0** untuk gejala, sebab, dan pilihan perbaikan. Ringkas: runtime TFLite 2.11.0 bawaan `tflite_flutter` 0.11.0 terlalu tua untuk op versi 12 yang dihasilkan TF 2.21.0.

### 7.1 Beranda kosong — `BoxConstraints forces an infinite height`

**Gejala.** Hanya bilah atas yang tergambar di HP; seluruh isi beranda tidak muncul. Logcat bersih tanpa pengecualian Flutter.

**Sebab.** `Row(crossAxisAlignment: CrossAxisAlignment.stretch)` di dalam `SliverList`. Tinggi `SliverList` tidak terbatas, sehingga `Row` meminta tinggi `Infinity`.

**Perbaikan.** Setiap `Row` dibungkus `IntrinsicHeight` **secara individual**.

> [!CAUTION]
> Jangan membungkus `Column` dengan `IntrinsicHeight` lalu berharap `Row` di dalamnya aman. `Column` meneruskan `maxHeight` tak terbatas ke anak non-flex, sehingga galat tetap muncul. `IntrinsicHeight` harus membungkus **`Row` yang memakai `stretch`**, bukan pembungkus luarnya.
>
> Sebagai aturan umum: **jangan pernah memakai `CrossAxisAlignment.stretch` di dalam `Row`/`Column` yang berada di kontainer bertinggi tak terbatas** (`SliverList`, `ListView`) tanpa `IntrinsicHeight` langsung pada `Row` tersebut.

Bukti perbaikan: ukuran tangkapan layar naik dari 30.353 B menjadi 243.109 B.

### 7.2 `RenderFlex overflowed by 0.873 pixels on the right`

Lokasi: `_KartuHasil` pada `hasil_screen.dart`. `Row` berisi `Text` + `Spacer` + `Text`.
Perbaikan: `Spacer` diganti `Flexible` pada kedua `Text` + `MainAxisAlignment.spaceBetween`. Baris sumbu 0 %/70 %/100 % memakai `Expanded` di tengah dengan `TextAlign.center` dan `ellipsis`.

### 7.3 `Undefined name 'SharePlus'`

`share_plus` yang terpasang adalah **10.1.4**, yang memakai `Share.shareXFiles(...)`, bukan API baru `SharePlus.instance.share(ShareParams(...))`.
Perbaikan: `Share.shareXFiles([XFile(path, mimeType: 'text/csv')], subject: ..., text: ...)`.

### 7.4 Layar berputar terus saat basis data gagal

`sqflite` melempar `Bad state: databaseFactory not initialized` di lingkungan uji. Panggilan `penyakitById` di dalam `HasilScreen` dan `DetailRiwayatScreen` tidak tertangkap sehingga `_memuat` tidak pernah menjadi `false`.
Perbaikan: bungkus dengan `try { } on Object catch (e) { debugPrint(...); }` agar layar selalu lanjut.

### 7.5 `pumpAndSettle timed out` pada uji widget

`CircularProgressIndicator` beranimasi tanpa henti saat basis data belum siap.
Perbaikan: ganti `pumpAndSettle()` dengan empat panggilan `pump(const Duration(milliseconds: 100))`.

### 7.6 Peringatan analisis lain

- `Unused import: '../utils/format_waktu.dart'` pada `home_screen.dart` → dihapus.
- `Unused import: 'dart:io'` pada `home_screen.dart` → dihapus.
- `The 'children' argument should be last in widget constructor invocations` pada `hasil_screen.dart` → urutan argumen dibetulkan.

`flutter analyze` terakhir: **`No issues found!`**

---

## 8. Sisa Pekerjaan

- [ ] **BLOKIR #1 — perbaiki pemuatan model di HP.** Lihat Bagian 0. Ini yang menghambat F-03..F-06.
- [ ] Setelah blokir beres: jalankan F-01..F-08 dan kumpulkan baris `[TFLite] <ms> ms | <kelas> <pct>% | aturan <Rx>` sebagai bukti NF-02.
- [ ] Uji kedua tema (`cmd uimode night yes|no`); tangkap layar setiap layar.
- [ ] Uji layar baru: Panduan Foto, Statistik (butuh >= 1 riwayat), Pengaturan (ganti tema, ekspor CSV, salin ringkasan, hapus semua).
- [ ] Bangun `--release` untuk mengukur ukuran APK (bahan BAB IV).
- [ ] Hitung akurasi model terintegrasi pada 927 citra uji memakai `split_test.csv`; buat matriks konfusi untuk BAB IV (hipotesis H4 >= 90 %). Kelas `TfliteClassifier` sudah menyediakan `identifikasiBatch`, `rataRataMs`, `persentilMs`.
- [ ] Jalankan daftar periksa ui-ux-pro-max sebelum penyerahan: HP kecil 375 px, lanskap, ukuran teks sistem terbesar, reduced-motion, kontras mode gelap terpisah, target sentuh >= 48 dp, tidak ada konten di balik safe area, tidak ada gulir horizontal.
- [ ] Tulis laporan penyimpangan & pengukuran BAB III/IV (8 butir di Bagian 6.5 + ukuran/latensi terukur vs 2,71 MB / 144,80 ms).
- [ ] Bersihkan berkas sementara: `D:\TUGAS AKHIR\ml\smoke_data`, `D:\TUGAS AKHIR\ml\output_smoke`, `D:\TUGAS AKHIR\ml\_smoke_train.py`, `D:\TUGAS AKHIR\ml\smoke_test.py`, `D:\TUGAS AKHIR\ml\_aar`; klon sementara `uiuxpro/`, `superpowers/`, `caveman/`; direktori kosong `android_home`/`adbhome`.
- [ ] Putuskan nasib `.agents\skills\generated` dan `.agents\skills\native` (tidak punya `SKILL.md`; artefak runtime caveman, aman dihapus).
- [x] Tambahkan uji render untuk `panduan_foto_screen`, `statistik_screen`, `pengaturan_screen` — 6 uji baru, total **49 lulus**.
- [x] **Uji `flutter test` & `flutter analyze` bersih** setelah semua perubahan sesi ini.
- [x] **APK debug dibangun ulang & dipasang** ke HP (fitur baru + model ikut).

---

## 9. Aturan yang Tidak Boleh Dilanggar

| Kode | Batasan |
|---|---|
| NF-01 | Identifikasi berjalan **sepenuhnya offline** |
| NF-02 | Target inferensi **< 1 detik** di perangkat |
| NF-03 | Minimum **Android 8.0 / API 26** |
| NF-04 | Antarmuka berbahasa **Indonesia** |
| NF-05 | Rekomendasi hanya menampilkan **bahan aktif** — tanpa merek dagang, tanpa dosis |

Tambahan:

- Ambang keyakinan **70 %** dengan aturan **R1–R5**.

| Aturan | Kelas |
|---|---|
| R1 | `blas` |
| R2 | `hawar_daun_bakteri` |
| R3 | `bercak_cokelat` |
| R4 | kelas lain |
| R5 | keyakinan rendah — citra tidak dikenali |

- Model dipakai **tanpa mengubah algoritma maupun dataset** milik penelitian terdahulu. Setiap penyimpangan wajib ditandai `[ASUMSI]` dan dilaporkan di BAB III.

---

## 10. Titik Masuk Kembali yang Cepat

Bila baru menyalakan ulang komputer dan ingin segera tahu keadaan:

```powershell
# 1. Model sudah ada?
Get-ChildItem "D:\TUGAS AKHIR\aplikasi TA\assets\models"

# 2. Metrik latih
Get-Content "D:\TUGAS AKHIR\ml\output\metrics.json" -Raw

# 3. APK ada?
Get-ChildItem "D:\TUGAS AKHIR\aplikasi TA\build\app\outputs\flutter-apk"

# 4. HP terpasang?
& "D:\android_sdk\platform-tools\adb.exe" devices
```

Yang harus terlihat: `padi_mobilenetv2.tflite` (2.847.440 B) pada langkah 1, dan serial `PBY94X65JB8HDIHY` berstatus `device` pada langkah 4.

---

## 11. Catatan Lingkungan Lain

- `git clone` mengembalikan exit 1 meski berhasil (git menulis ke stderr).
- Klon skill pihak ketiga tersimpan di `D:\TUGAS AKHIR\.agents\skills\` (40 direktori) dari tiga repositori: `nextlevelbuilder/ui-ux-pro-max-skill`, `obra/superpowers`, `JuliusBrussee/caveman`. Aturan ruang kerja ada di `D:\TUGAS AKHIR\.agents\rules\AGENTS.md`.
- `D:\TUGAS AKHIR` bukan repositori git (`Test-Path "D:\TUGAS AKHIR\.git"` → `False`).
- Ruang disk bebas belum diketahui (`fsutil volume diskfree` ditolak).
- GPU tidak dapat dipakai untuk TensorFlow di mesin ini (tanpa WSL).
