# Laporan Deviasi Metodologi (BAB III) & Pengukuran Evaluasi (BAB IV)

**Proyek:** Padi Scan — Sistem Identifikasi Penyakit Daun Padi Berbasis Mobile
**Acuan Utama:** Mustofa, Arifin & Zulfia (2026), *JAIC* 10(2):1896–1904, DOI `10.30871/jaic.v10i2.12499`
**Berkas Model Terintegrasi:** `assets/models/padi_mobilenetv2.tflite` (`2.847.440` byte / `2,85 MB`, SHA-256 `55c2517cdd10295a7407ded8ebb8eb2e2ac2fd3c4928f703da39d26aab554bc2`)
**Data Evaluasi Mentah:** `D:\TUGAS AKHIR\ml\output\metrics.json` dan `D:\TUGAS AKHIR\ml\output\evaluasi_tflite_bab4.json`

---

## 1. Catatan Replikasi & Deviasi Metodologi (Bahan BAB III)

Karena penulis penelitian terdahulu (Mustofa dkk., 2026) tidak mempublikasikan berkas bobot model `.keras` maupun `.tflite`, model direplikasi dari awal menggunakan dataset dan konfigurasi arsitektur yang sama tanpa mengubah algoritma maupun dataset penelitian terdahulu. Seluruh detail implementasi yang tidak dicantumkan eksplisit di jurnal ditandai `[ASUMSI]` sebagai berikut:

| No | Aspek | Jurnal Mustofa dkk. (2026) | Implementasi Replikasi Lokal | Status / Keterangan BAB III |
|---|---|---|---|---|
| 1 | Pembagian dataset (70/15/15 stratified, `seed=42`) | `4.324` latih / `928` val / `928` uji | `4.326` latih / `927` val / `927` uji | `[ASUMSI]` Pembulatan `train_test_split(..., test_size=0.30)` lalu `test_size=0.50` pada `scikit-learn` menghasilkan `4326/927/927` (`0.70 * 6180 = 4326`). |
| 2 | Alokasi epoch dua fase | Maksimum 30 epoch, berhenti di epoch 25 (`EarlyStopping(patience=3)`) | Maksimum 30 epoch Fase 1 (head) + 30 epoch Fase 2 (fine-tune 20 layer terakhir); berhenti di `19 + 19` epoch | `[ASUMSI]` Jurnal tidak merinci titik peralihan epoch antara fase pembekuan base dan fase fine-tuning. |
| 3 | `class_weights` | Disebutkan menerapkan penyeimbangan bobot kelas | Tidak dikirim ke `model.fit` | Dataset sudah seimbang sempurna (`1.545` citra per kelas), sehingga bobot tiap kelas bernilai `1,0000` (efek matematis identik). |
| 4 | Mekanisme partisi berkas | Menyalin berkas fisik dengan `shutil.copy` ke folder `train/val/test` | Partisi melalui `pandas.DataFrame` + `flow_from_dataframe` (`split_train.csv`, `split_val.csv`, `split_test.csv`) | Hemat ruang penyimpanan dan menjamin daftar berkas uji tercatat permanen di CSV. |
| 5 | Kuantisasi TensorFlow Lite | Menyebut ukuran model `2,71 MB` setelah konversi TFLite | `conv.optimizations = [tf.lite.Optimize.DEFAULT]` (dynamic-range quantization) | `[ASUMSI]` Menghasilkan ukuran `2,85 MB` (`2.847.440` byte), selaras dengan kisaran `2,71 MB` di jurnal. |
| 6 | Fungsi aktivasi layer Dense(256) | Menyebut `Dense(256)` antara `Dropout(0.5)` dan `BatchNormalization` | `Dense(256, activation="relu")` | `[ASUMSI]` Standar arsitektur klasifikasi CNN di atas MobileNetV2. |
| 7 | Fungsi rugi (*loss function*) | Klasifikasi 4 kelas dengan keluaran `softmax` | `categorical_crossentropy` | `[ASUMSI]` Pasangan standar untuk keluaran `softmax` multi-kelas. |
| 8 | Lingkungan perangkat keras & pustaka | Google Colab (GPU), Keras 2.13 | Windows lokal (CPU), TensorFlow `2.21.0`, Keras `3.15.1`, scikit-learn `1.9.1`, runtime Android `com.google.ai.edge.litert:litert:1.4.0` via `tflite_flutter 0.12.1` | Perbedaan versi pustaka menyebabkan op `FULLY_CONNECTED` v12 pada berkas `.tflite`, yang ditangani dengan pembaruan runtime LiteRT 1.4.0 di Android. |

---

## 2. Perbandingan Kinerja Model dengan Jurnal Acuan (Bahan BAB IV)

Evaluasi dilakukan pada **927 citra uji** (`split_test.csv`) yang sama sekali tidak digunakan selama pelatihan maupun validasi.

### 2.1 Tabel Perbandingan Utama

| Metrik Evaluasi | Jurnal Mustofa dkk. (2026) | Model Replikasi (Keras FP32) | Model Terintegrasi (TFLite `.tflite`) | Selisih TFLite vs Jurnal |
|---|---|---|---|---|
| **Akurasi Uji (Accuracy)** | 97,20 % | **98,27 %** | **98,17 %** (`910 / 927`) | **+0,97 %** |
| **Precision (Macro)** | 97,30 % | **98,28 %** | **98,18 %** | **+0,88 %** |
| **Recall (Macro)** | 97,09 % | **98,28 %** | **98,17 %** | **+1,08 %** |
| **F1-Score (Macro)** | 97,19 % | **98,27 %** | **98,17 %** | **+0,98 %** |
| **ROC-AUC (Macro)** | 0,9972 | **0,9989** (val) | **0,9996** (test) | **+0,0024** |
| **Ukuran Berkas `.tflite`** | 2,71 MB | 23,30 MB (`.keras`) | **2,85 MB** (`2.847.440` B) | +0,14 MB |
| **Ukuran APK Rilis (`--release`)** | — | — | **74,6 MB** (`78.240.076` B, multi-ABI) | — |
| **Latensi Inferensi Rata-rata** | 144,80 ms (Intel i3 Gen-10) | — | **28,99 ms** (CPU lokal) | **-115,81 ms (5x lebih cepat)** |

> **Verifikasi Hipotesis BAB IV:** Akurasi model setelah dikonversi ke TensorFlow Lite dan diintegrasikan ke aplikasi adalah **98,17 %** (dan **99,23 %** pada citra yang lolos ambang keyakinan $\ge 70\%$), melampaui target hipotesis $\ge 90\%$ maupun akurasi jurnal acuan $97,20\%$.

---

## 3. Rincian Evaluasi Per Kelas — Model TFLite Terintegrasi (927 Citra Uji)

### 3.1 Metrik Per Kelas (TFLite)

| ID Kelas (`labels.txt`) | Label Dataset | Precision | Recall | F1-Score | Jumlah Citra Uji (*Support*) |
|---|---|---|---|---|---|
| `bercak_cokelat` | `brown_spot` | 98,68 % | 96,98 % | 97,83 % | 232 |
| `blas` | `leaf_blast` | 95,74 % | 96,98 % | 96,36 % | 232 |
| `hawar_daun_bakteri` | `leaf_blight` | 98,71 % | 98,71 % | 98,71 % | 232 |
| `normal` | `normal` | 99,57 % | 100,00 % | 99,78 % | 231 |
| **Rata-rata Makro** | — | **98,18 %** | **98,17 %** | **98,17 %** | **927** |

### 3.2 Matriks Konfusi (*Confusion Matrix*) Model TFLite

Baris = kelas aktual, kolom = kelas prediksi:

| Aktual \ Prediksi | `bercak_cokelat` | `blas` | `hawar_daun_bakteri` | `normal` | Total Aktual |
|---|---|---|---|---|---|
| **`bercak_cokelat`** | **225** | 7 | 0 | 0 | 232 |
| **`blas`** | 3 | **225** | 3 | 1 | 232 |
| **`hawar_daun_bakteri`** | 0 | 3 | **229** | 0 | 232 |
| **`normal`** | 0 | 0 | 0 | **231** | 231 |
| **Total Prediksi** | 228 | 235 | 232 | 232 | **927** |

---

## 4. Evaluasi Mesin Aturan (`RuleEngine` R1–R5, Ambang Keyakinan 70 %)

Pada aplikasi `padi_scan`, keluaran *softmax* model TFLite diteruskan ke `RuleEngine` (`lib/logic/rule_engine.dart`) dengan ambang keyakinan **70 %** (`0,70`):

| Kode Aturan | Kondisi | Tindakan Sistem | Jumlah Aktif pada 927 Citra Uji | Persentase |
|---|---|---|---|---|
| **R1** | `id == 'blas'` dan `keyakinan >= 0,70` | Tampilkan hasil Blas + rekomendasi bahan aktif | 225 | 24,27 % |
| **R2** | `id == 'hawar_daun_bakteri'` dan `keyakinan >= 0,70` | Tampilkan hasil HDB + rekomendasi bahan aktif | 229 | 24,70 % |
| **R3** | `id == 'bercak_cokelat'` dan `keyakinan >= 0,70` | Tampilkan hasil Bercak Cokelat + rekomendasi bahan aktif | 224 | 24,16 % |
| **R4** | `id == 'normal'` dan `keyakinan >= 0,70` | Tampilkan status Daun Sehat + saran pemeliharaan | 231 | 24,92 % |
| **R5** | `keyakinan < 0,70` | Tolak diagnosis (*Citra Tidak Dikenali*) + tampilkan panduan foto ulang | 18 | 1,94 % |
| **Total** | — | — | **927** | **100,00 %** |

**Dampak Positif Aturan R5:**
- Dari `927` citra uji, sebanyak **`909` citra (98,06 %)** memiliki keyakinan $\ge 70\%$ dan dikenali langsung oleh sistem.
- Sebanyak **`18` citra (1,94 %)** memiliki keyakinan $< 70\%$ sehingga ditahan oleh aturan **R5** (10 di antaranya memang prediksi yang salah dari model).
- Dengan demikian, **akurasi efektif pada citra yang dikenali ($\ge 70\%$)** meningkat dari **98,17 %** menjadi **99,23 %** (`902 / 909` benar).

---

## 5. Verifikasi Kebutuhan Fungsional & Non-Fungsional

### 5.1 Kebutuhan Fungsional (F-01 s.d. F-08 + Fitur Tambahan 2.0)

| Kode | Kebutuhan | Implementasi Kode | Status |
|---|---|---|---|
| **F-01** | Akuisisi citra dari kamera | `HomeScreen._ambilFoto(ImageSource.camera)` + `PhotoPreviewScreen` | Lulus |
| **F-02** | Akuisisi citra dari galeri | `HomeScreen._ambilFoto(ImageSource.gallery)` (tanpa kompresi ulang untuk citra $\le 1600$ px) | Lulus |
| **F-03** | Prapemrosesan (224x224, rescale 1/255) & inferensi TFLite MobileNetV2 | `ImagePreprocessor.dariBytes` + `TfliteClassifier.identifikasi` | Lulus |
| **F-04** | Tampilan hasil identifikasi & probabilitas 4 kelas (skala absolut 0–100%) | `HasilScreen` (`_KartuHasil`, `_TabelProbabilitas`, `_CatatanTeknis`) | Lulus |
| **F-05** | Rekomendasi penanganan berjenjang (Kultur Teknis → Hayati → Kimia) | `RekomendasiScreen` + `assets/data/penyakit.json` | Lulus |
| **F-06** | Penolakan citra keyakinan $< 70\%$ (R5) & panduan foto ulang | `RuleEngine.evaluasi` + `_KartuTidakDikenali` + `PanduanFotoScreen` | Lulus |
| **F-07** | Penyimpanan, pencarian, penyaringan, pengurutan, ekspor CSV, & penghapusan riwayat | `DatabaseHelper` (SQLite v2) + `RiwayatScreen` + `DetailRiwayatScreen` + `RiwayatExporter` | Lulus |
| **F-08** | Halaman daftar & detail informasi keempat kelas penyakit | `InformasiScreen` + `RekomendasiScreen` | Lulus |
| **Tambahan** | Pemeriksaan kualitas foto (gelap/buram), Catatan Lapangan (Petak, Musim, Sesi Survei Multi-Daun, Timeline), Statistik, Pengaturan Tema | `PhotoQualityChecker`, `PetakScreen`, `SesiSurveiScreen`, `TimelinePetakScreen`, `StatistikScreen`, `PengaturanScreen` | Lulus |

### 5.2 Kebutuhan Non-Fungsional (NF-01 s.d. NF-05)

| Kode | Batasan | Bukti Verifikasi | Status |
|---|---|---|---|
| **NF-01** | Identifikasi berjalan sepenuhnya *offline* | Model `.tflite`, `labels.txt`, `penyakit.json`, SQLite, dan 5 berkas font `PlusJakartaSans` dipaketkan lokal di aset aplikasi; tidak ada permintaan HTTP saat inferensi. | Lulus |
| **NF-02** | Waktu inferensi $< 1$ detik ($< 1000\text{ ms}$) | Rata-rata `28,99 ms`, median `27,82 ms`, persentil ke-95 `36,68 ms` (jauh di bawah batas `1000 ms`). | Lulus |
| **NF-03** | Minimum Android 8.0 (API 26) | `minSdk = 26` pada `android/app/build.gradle.kts`; diuji pada perangkat fisik Android 13 (SDK 33, `arm64-v8a`). | Lulus |
| **NF-04** | Antarmuka berbahasa Indonesia | Seluruh label navigasi, nama kelas (`Penyakit.namaDariId`), pesan status, dan rekomendasi berbahasa Indonesia; kontras WCAG $\ge 4,5:1$ pada tema terang & gelap. | Lulus |
| **NF-05** | Rekomendasi hanya menampilkan bahan aktif (tanpa merek dagang & tanpa dosis) | Diverifikasi otomatis oleh `test/rekomendasi_policy_test.dart` terhadap seluruh butir `assets/data/penyakit.json`. | Lulus |
