# PRD Padi Scan 2.0 — Revisi Menyeluruh Aplikasi Tugas Akhir

**Status:** rancangan untuk ditinjau, belum menjadi bukti hasil penelitian.  
**Tanggal:** 17 November 2026.  
**Pemilik produk/penelitian:** Arnanda Setya Nosa Putra.  
**Platform:** Android 8.0+ (API 26+), Flutter, inferensi TensorFlow Lite di perangkat.  
**Dasar utama:** `../../Proposal_TA_Arnanda_Padi_v14.docx`, `../../jurnal mustofa.pdf`, `../../dataset penelitian mustofa/`, kode dan artefak lokal. Path tersebut relatif terhadap folder `docs/` dan menunjuk ke folder induk proyek bila dihitung dari lokasi dokumen ini; lokasi absolut tercantum pada bagian 1.

**Spesifikasi tampilan lengkap:** [UI Redesign Padi Scan 2.0](./UI-REDESIGN-PADI-SCAN-2.0.md) memuat arah visual, wireframe, token, navigasi, tiap layar, komponen, state, dan uji aksesibilitas. Dokumen itu merinci §6 dan §10 PRD ini.

> **Keputusan penting:** target “sama persis seperti jurnal” berarti dua pekerjaan berbeda: memperoleh dan memverifikasi bobot asli penulis (kesetaraan artefak), atau mereplikasi prosedur yang dapat diungkap jurnal (kesetaraan metode). Bobot identik dan akurasi lapangan tidak dapat dijanjikan hanya dari PDF. Jangan menamai replikasi lokal sebagai model asli Mustofa.

## 1. Sumber, ruang lingkup, dan hierarki bukti

1. Proposal v14: `D:\TUGAS AKHIR\Proposal_TA_Arnanda_Padi_v14.docx`, terutama Bab I dan Bab III. Jika rancangan ini mengubah kebutuhan F-01–F-08, NF-01–NF-05, aturan R1–R5, atau protokol uji, proposal/Bab III perlu diselaraskan sebelum laporan akhir.
2. Mustofa, Arifin, Zulfia, *Multi-Class Classification of Rice Leaf Diseases Using MobileNetV2 Architecture with Transfer Learning*, JAIC 10(2), 2026, hlm. 1896–1904, DOI `10.30871/jaic.v10i2.12499`: `D:\TUGAS AKHIR\jurnal mustofa.pdf`. Angka jurnal adalah hasil penulis pada data uji mereka, bukan hasil aplikasi ini.
3. Dataset lokal: `D:\TUGAS AKHIR\dataset penelitian mustofa\` (6.180 JPEG: `brown_spot`, `leaf_blast`, `leaf_blight`, `normal`; masing-masing 1.545). Sumber yang dikutip jurnal: Kaggle *Data Rice Leaf FN*.
4. Artefak replikasi: `D:\TUGAS AKHIR\ml\train_padi.py`, `ml\output\metrics.json`, `ml\output\split_*.csv`, `ml\output\padi_mobilenetv2.tflite`; salinan dalam `aplikasi TA\assets\models\` memiliki hash SHA-256 sama dengan keluaran lokal. Belum ada bukti bahwa hash tersebut sama dengan model penulis jurnal.
5. Aplikasi: `lib/`, `assets/`, `test/`, `design-system/padi-scan/`, dan `docs/CATATAN-PERUBAHAN-PADI-SCAN.md`. README dan catatan perubahan mengandung status lama yang bertentangan; kode dan artefak terpasang menjadi sumber kondisi implementasi saat ini.

**Label bukti dalam PRD:** **[J]** dilaporkan jurnal, **[P]** diwajibkan proposal, **[L]** teramati pada berkas lokal, **[R]** rekomendasi desain yang perlu diuji, **[ASUMSI]** detail metode yang tidak cukup dijelaskan jurnal. Nilai [R] bukan klaim hasil.

## 2. Ringkasan produk

Padi Scan membantu petani mengambil atau memilih foto **satu daun padi per inferensi** dan memperoleh indikasi awal empat kelas: blas daun, hawar daun bakteri, bercak cokelat, atau daun tampak sehat. Hasil dapat dikelompokkan per petak dan musim, lalu beberapa pemeriksaan satu-daun dapat dicatat dalam satu sesi survei. Aplikasi berjalan tanpa internet, menyajikan tindakan awal yang bersumber, menyimpan riwayat lokal, dan menyatakan ketidakpastian secara jujur. Peran utama penelitian tetap rekayasa perangkat lunak: penerapan model terdahulu di Android dan pengukuran fungsionalitas, kinerja, akurasi terintegrasi, serta kemudahan penggunaan. **Tidak ada klaim diagnosis definitif, identifikasi semua penyakit/hama, estimasi prevalensi sawah, atau penilaian tingkat keparahan.**

### 2.1 Masalah dan hasil yang dicari

- Petani perlu mengenali gejala daun dan memperoleh langkah awal di sawah tanpa jaringan. [P]
- Alur harus jelas bagi pengguna nonteknis: foto, baca hasil, pilih tindakan. [R]
- Hasil yang lemah, gambar gagal dibaca, dan model gagal dimuat harus memiliki status serta pemulihan yang berbeda. [R]
- Replikasi model dan evaluasinya harus dapat diaudit tanpa menyamakan angka uji tertutup dengan akurasi lapangan. [R]
- Pengguna dapat menghubungkan pemeriksaan dari petak dan musim yang sama serta melakukan survei beberapa daun secara berurutan. [R]

### 2.2 Pengguna

| Persona | Kebutuhan | Keputusan desain |
|---|---|---|
| Petani padi, pengguna utama | Cepat, bahasa sehari-hari, bekerja offline, tindakan yang dapat diikuti | CTA foto besar, hasil ringkas, rekomendasi bertahap, target sentuh 48 dp |
| Penyuluh/PPL/POPT, pendamping | Memeriksa foto dan konteks hasil, melihat sumber rekomendasi | Detail hasil yang bisa dibuka, riwayat dan ekspor dengan persetujuan pengguna |
| Peneliti/penguji, bukan persona utama layar beranda | Bukti model, latensi, aturan, versi, hasil uji | Panel “Detail teknis” dan artefak uji terpisah dari alur petani |

### 2.3 Tujuan, kriteria, dan non-tujuan

| Tujuan | Kriteria penerimaan | Sumber |
|---|---|---|
| Semua fungsi inti berjalan | F-01–F-08 dan skenario perluasan relevan lulus black-box | [P] target H1 |
| Inferensi offline | Mode pesawat: foto, inferensi, hasil, rekomendasi, riwayat tetap berjalan; tanpa permintaan jaringan | [P] NF-01 |
| Latensi inferensi | Rerata inferensi model <1.000 ms pada tiap perangkat uji; catat juga total waktu foto-siap sampai hasil | [P] NF-02; perbedaan metrik dijelaskan di §12 |
| Usability | SUS rata-rata ≥68 dari 10–20 petani; laporkan semua skor dan jumlah responden | [P] H3 |
| Akurasi setelah integrasi | ≥90% pada set uji yang sah; laporkan denominator, split, kelas, confidence interval, dan ketidakpastian akibat kebocoran | [P] H4, [R] integritas |
| Pengamatan per petak | Petak/musim, sesi survei, dan timeline lokal dapat dibuat, dibuka kembali, serta dihapus tanpa merusak hasil lain | [R] perluasan produk; instrumen uji TA perlu diperbarui |

**Di luar ruang lingkup versi TA:** diagnosis batang/malai/akar, identifikasi hama, peta penyebaran penyakit, prediksi panen, geolokasi otomatis, backend/cloud/login, marketplace pestisida, chat AI, rekomendasi dosis, notifikasi berbasis cuaca, retraining pada data pengguna. Fitur tersebut mengubah pertanyaan riset, membutuhkan data/validasi baru, atau merusak sifat offline.

## 3. Audit keadaan sekarang dan masalah yang harus diselesaikan

| Area | Keadaan kode saat ini [L] | Kebutuhan revisi |
|---|---|---|
| Navigasi | `HomeScreen` memuat pintasan Riwayat, Info, Statistik, Pengaturan; layar lain memakai `Navigator.push` | Hierarki mudah diprediksi, CTA pemeriksaan selalu mudah dijangkau |
| Foto | `ImagePicker` langsung memilih lalu menyalin dan menginferensi | Pratinjau, konfirmasi objek satu daun, ulang foto, pemeriksaan kualitas yang bisa diabaikan dengan penjelasan |
| Hasil | Nama kelas, softmax empat kelas, ambang 70%, latensi; rekomendasi di layar terpisah | Ringkasan dan satu langkah pertama di hasil; angka rinci ditaruh dalam detail |
| Pengukuran waktu | `Stopwatch` saat ini dimulai sebelum prapemrosesan dan berhenti sesudah `Interpreter.run` | Pisahkan waktu prapemrosesan, inferensi murni, dan total agar label metrik akurat |
| Ketidakpastian | Softmax <70% disebut “citra tidak dikenali” | Bedakan “hasil belum meyakinkan” dari “bukan daun padi”; threshold bukan detektor luar-domain |
| Riwayat | SQLite menyimpan foto, kelas, satu skor dan waktu | Simpan prediksi empat kelas, status, versi/hash model, aturan, dan waktu; migrasi tanpa kehilangan data lama |
| Statistik | Angka dari riwayat lokal dan skor softmax | Label “ringkasan pemeriksaan perangkat ini”; jangan menyebut prevalensi, akurasi, atau tingkat serangan |
| Pengetahuan | JSON dan SQLite menyimpan rekomendasi; hayati/kimia digabung | Pisahkan kategori dan audit seluruh butir terhadap NF-05 serta sumber per butir |
| Model | Salinan TFLite replikasi lokal, ukuran 2.847.440 byte | Provenance eksplisit; kesetaraan metode dan artefak diuji terpisah |
| Dokumentasi | README menyebut model belum ada, catatan perubahan memuat bagian “blokir selesai” dan bagian lama “belum diperbaiki” | Satu status implementasi terkini dan changelog bertanggal |

**Masalah konten konkret:** `assets/data/penyakit.json` memuat “100 mikrogram/ml” dan “2%” pada rekomendasi HDB. Ini adalah konsentrasi/dosis dan bertentangan dengan NF-05. Sebelum rilis, hapus angka dosis dari konten pengguna atau ubah kebijakan proposal secara resmi. Prioritas PRD: tetap patuhi NF-05; telaah substansi dengan pembimbing/penyuluh. Ada pula anjuran perlakuan benih dengan suhu/durasi; tentukan apakah itu termasuk dosis yang dibatasi NF-05 sebelum menampilkan; jangan ubah fakta ilmiah tanpa verifikasi.

## 4. Pendekatan dan keputusan

| Pendekatan | Keuntungan | Risiko/keterbatasan | Putusan |
|---|---|---|---|
| Memoles layar yang ada | Cepat | Kontrak data dan audit model tetap lemah | Ditolak untuk revisi menyeluruh |
| Menyusun ulang fitur dalam Flutter dan migrasi SQLite bertahap | Memanfaatkan aplikasi berjalan, memperbaiki UX dan integritas bukti | Perlu migrasi dan uji regresi | **Dipilih** |
| Ganti framework/server dan bangun ulang | Bebas mendesain ulang | Menambah risiko, biaya, dan menyimpang dari proposal offline Flutter | Ditolak |

Keputusan visual awal: pertahankan arah palet **Soft Sage** yang sudah diminta pengguna serta Plus Jakarta Sans lokal. Cari tampilan bersih, kontras, dan terbaca di sawah; warna tidak boleh menyatakan diagnosis sendirian. Master design-system lama menghasilkan pola landing page dan font Fira Code yang tidak cocok dengan aplikasi petani; dokumen `PALET-SOFT-SAGE.md` dan `OVERRIDES.md` adalah baseline yang lebih relevan. Validasi desain aktual melalui prototipe dan SUS; PRD tidak menetapkan estetika sebagai hasil uji.

## 5. Fitur yang direkomendasikan

P0 = inti TA/harus sebelum uji; P1 = tambahan yang **dipilih masuk target revisi 2.0**; P2 = setelah TA. Bila waktu atau hasil uji membatasi P1, catat perubahan cakupan secara eksplisit dan perbarui skenario black-box sebelum uji final. Kriteria rilis minimum tetap seluruh F-01–F-08.

| ID | Fitur | Prioritas | Mengapa | Batas aman dan ukuran selesai |
|---|---|---|---|---|
| A01 | Ambil foto kamera dan pilih galeri | P0 | Input utama F-01/F-02 | Izin ditangani, pembatalan tidak menyimpan riwayat |
| A02 | Pratinjau dan konfirmasi satu daun padi | P0 | Memperjelas objek dan mengurangi foto salah | Crop manual ditunda; perubahan crop memerlukan uji preprocessing/model tersendiri |
| A03 | Panduan foto singkat sebelum/ketika pengambilan | P0 | Kondisi fokus/cahaya diasumsikan proposal | Satu layar ringkas, dapat dilewati pengguna berulang |
| A04 | Pemeriksaan kualitas teknis sebelum inferensi | P1 | Foto gelap/buram meningkatkan risiko hasil buruk | Heuristik deterministik hanya memberi peringatan; tidak menjamin daun padi; ambang dikalibrasi |
| A05 | Inferensi MobileNetV2 di perangkat | P0 | F-03 dan NF-01 | Tensor input/output/label diverifikasi otomatis; tanpa model fallback diagnosis palsu |
| A06 | Hasil empat keadaan dan tindakan berikutnya | P0 | F-04/F-06, pemahaman ketidakpastian | Status: gagal teknis, foto perlu diulang, hasil belum meyakinkan, hasil terklasifikasi; kelas sehat diperlakukan tersendiri |
| A07 | Rekomendasi bertingkat beserta sumber | P0 | F-05 | Kultur teknis lebih dulu; hayati dan kimia terpisah; tanpa merek/dosis |
| A08 | Kapan perlu menghubungi PPL/POPT | P1 | Membantu saat hasil meragukan/serangan meluas | Panduan eskalasi umum, bukan keputusan medis/kimia otomatis; konten ditinjau ahli |
| A09 | Riwayat lokal dengan foto dan detail hasil | P0 | F-07 | Ada hapus satu/semua, kegagalan foto hilang ditangani |
| A10 | Cari, filter, urut riwayat | P1 | Memudahkan peninjauan pemeriksaan | Filter tidak mengubah data tersimpan; hasil tak meyakinkan dapat ditemukan |
| A11 | Katalog 4 kelas dengan gejala dan pembeda sederhana | P0 | F-08 | Sumber per informasi; tidak menyebut gejala yang model tidak memeriksa sebagai hasil klasifikasi |
| A12 | Bandingkan hasil foto dengan panduan gejala | P1 | Menjembatani prediksi dan observasi pengguna | Hanya checklist observasi manual; tidak masuk skor model atau klaim akurasi |
| A13 | Ringkasan pemeriksaan lokal | P1 | Melihat pola pemakaian sendiri | Jangan inferensi prevalensi atau efektivitas pengendalian |
| A14 | Ekspor CSV/ringkasan untuk penyuluh | P1 | Memudahkan diskusi lapangan | Ekspor eksplisit, peringatan bahwa aplikasi tujuan dapat mengirim data; identitas/foto tidak otomatis ikut |
| A15 | Pengaturan aksesibilitas/tema dan pengelolaan data | P1 | Kemudahan baca dan kontrol privasi | Tema terang/gelap/sistem, data lokal, konfirmasi hapus |
| A16 | Detail teknis dan provenance model | P0 untuk penelitian, tersembunyi dari alur utama | Mencegah klaim asal model keliru | Hash, tanggal build, asal bobot, preprocessing, label dan status validasi terlihat |
| A17 | Pengingat pemantauan manual | P2 | Menolong tindak lanjut | Harus opt-in, lokal, tidak memberi diagnosis baru |
| A18 | Catatan tindak lanjut per hasil | P2 | Memantau tindakan pengguna | Teks manual, bukan pengukuran efektivitas atau model baru |
| A19 | Petak dan musim tanam | P1 | Riwayat memperoleh konteks lokasi kerja dan siklus tanam | Nama petak manual, tanggal tanam/varietas opsional; tanpa GPS wajib |
| A20 | Sesi survei beberapa daun | P1 | Pengamatan berulang menjadi satu kegiatan yang dapat ditinjau | Satu foto = satu inferensi; ringkasan adalah jumlah sampel, bukan prevalensi sawah |
| A21 | Timeline pemantauan per petak | P1 | Pemeriksaan lintas waktu dapat ditinjau bersama | Tampilkan urutan dan jumlah hasil; jangan otomatis menyimpulkan tren penyakit/keparahan |
| A22 | Panduan gejala di luar cakupan model | P2 | Pengguna tahu kapan foto daun bukan jalur yang tepat | Pertanyaan manual dan arahan ke penyuluh; tidak menambah kelas/prediksi MobileNet |
| A23 | Rencana tindakan PHT per fase tanam | P2 | Tindakan lapangan lebih kontekstual | Fase diisi manual; aturan dan konten divalidasi ahli; tanpa merek/dosis |
| A24 | Mode belajar mengenali gejala | P2 | Literasi gejala meningkat melalui latihan | Jawaban contoh bersumber; tidak diperlakukan sebagai hasil pemeriksaan |

### 5.1 Paket fitur tambahan yang dipilih untuk revisi 2.0

Daftar ini adalah **cakupan implementasi yang direncanakan**, bukan klaim bahwa fitur sudah selesai. Fitur lama yang ditingkatkan dibedakan dari fitur baru. Semuanya tetap berjalan offline dan tidak mengubah empat kelas MobileNetV2.

| Masuk revisi | Kondisi saat ini | Perubahan yang dibangun | Bukti selesai |
|---|---|---|---|
| Pratinjau dan konfirmasi foto (A02) | Kamera/galeri langsung menjalankan klasifikasi | Layar foto utuh, “Periksa foto”, “Ambil ulang”, konfirmasi satu daun | Batal/ulang tidak menyimpan entri; foto terpilih benar dipakai inferensi |
| Peringatan kualitas foto (A04) | Panduan berupa teks, tanpa evaluasi foto | Cek blur/kegelapan yang terukur; alasan dan opsi foto ulang atau lanjut | Foto tantangan menampilkan alasan tepat; hasil tidak pernah disebut “bukan padi” oleh heuristik |
| Hasil dengan empat keadaan (A06) | Hasil/skor dan R5 sudah ada | Bedakan gagal teknis, foto bermasalah, hasil kurang meyakinkan, terklasifikasi/sehat; langkah pertama jelas | Tiap keadaan punya pesan dan aksi pemulihan; kimia tidak tampil pada hasil tidak sah |
| Langkah penanganan berjenjang (A07) | Rekomendasi panjang; hayati/kimia satu kelompok | “Lakukan dulu”, hayati, bahan aktif, sumber per butir | Kategori benar; seluruh konten tanpa merek/dosis; tinjauan isi tercatat |
| Kapan minta bantuan PPL/POPT (A08) | Hanya beberapa butir sumber | Panduan eskalasi saat ragu atau gejala meluas | Ditinjau pembimbing/ahli; tidak mengklaim penilaian tingkat keparahan otomatis |
| Pencarian dan filter riwayat yang disederhanakan (A10) | Cari/filter/urut sudah ada | Desain ulang dan paging; hasil lama dan status ragu ikut dicari | Semua entri dapat ditemukan, tanpa batas 100 yang diam-diam memangkas daftar |
| Pembanding gejala manual (A12) | Informasi penyakit ada, belum terhubung jelas ke hasil | Checklist observasi di detail hasil/edukasi | Tidak mengubah probabilitas atau diagnosis; sumber gejala ditampilkan |
| Ekspor ringkasan untuk konsultasi (A14) | CSV dan salin ringkasan sudah ada | Pratinjau isi; versi model/status tercantum; foto opt-in terpisah | Ekspor hanya tindakan pengguna; data yang tidak tersedia ditulis “tidak dicatat” |
| Audit model di layar Tentang (A16) | Nama model ditampilkan tanpa asal/versi yang jelas | Asal “replikasi lokal”/“artefak penulis” sesuai bukti, hash dan versi | Metadata cocok manifest/model terpasang; tanpa klaim identik yang belum terbukti |

**Tetap ada dan dipoles:** kamera/galeri A01, panduan foto A03, inferensi A05, riwayat A09, katalog penyakit A11, statistik lokal A13, tema/data A15. **Modul utama baru yang masuk target 2.0:** A19–A21. **Tahap lanjutan setelah evaluasi TA:** A17–A18 dan A22–A24. **Tidak masuk target 2.0:** crop manual, deteksi otomatis non-padi, penyakit tambahan, tingkat keparahan, peta, cuaca, akun, dan cloud.

**Prioritas eksekusi:** (1) pratinjau + status hasil + rekomendasi, (2) bukti model + migrasi riwayat, (3) petak/musim + survei + timeline, (4) kualitas foto + eskalasi + pembanding gejala, (5) pencarian/paging + ekspor. Keberhasilan setiap fitur tambahan diukur dengan skenario black-box baru; tugas inti SUS tetap foto→hasil→rekomendasi dan modul baru diuji dengan tugas tambahan yang dilaporkan terpisah.

### 5.2 Modul utama baru: spesifikasi A19–A21

Ketiga modul membentuk satu alur **petak → musim → sesi survei → pemeriksaan daun → timeline**. Pengamatan rutin adalah prinsip pengelolaan hama terpadu menurut [Ditjen Tanaman Pangan Kementan](https://tanamanpangan2.pertanian.go.id/artikel/pengendalian-hama-terpadu-pada-tanaman-padi%E2%81%A0). Penerapan alur di bawah adalah keputusan desain produk [R], bukan protokol pengukuran intensitas serangan yang telah divalidasi.

| ID | Perilaku rinci | Kondisi penerimaan |
|---|---|---|
| A19 Petak/musim | Pengguna membuat nama petak manual; varietas, tanggal tanam, dan catatan lokasi opsional. Satu petak dapat punya banyak musim. Pemeriksaan boleh disimpan tanpa petak agar alur cepat pertama kali tetap mudah. Musim dapat ditandai selesai tanpa menghapus data. | Dua petak dan dua musim tidak tercampur; data tetap ada setelah restart/mode pesawat; pemeriksaan lama ditampilkan sebagai “Belum dikelompokkan” dan boleh dipindah manual. |
| A20 Survei beberapa daun | Dari petak/musim pengguna membuka sesi, memotret beberapa daun **secara berurutan**; setiap foto mendapat hasil dan status tersendiri. Sesi dapat dijeda/dilanjutkan/diakhiri. Ringkasan hanya menampilkan jumlah foto, jumlah per kelas, dan jumlah belum meyakinkan/gagal. | Scan tunggal tetap tersedia; sesi 5 foto menghasilkan 5 entri dan 1 ringkasan; pembatalan satu foto tidak membatalkan foto lain; hasil rendah tidak masuk hitungan kelas penyakit. |
| A21 Timeline petak | Daftar pemeriksaan/sesi menurut tanggal dengan filter musim, foto, status dan ringkasan jumlah. Pengguna membuka kembali hasil asli serta membandingkan catatan **tanpa skor tren otomatis**. | Urutan waktu benar, filter musim konsisten, data legacy tidak hilang, tulisan “jumlah sampel diperiksa” selalu tampil; tidak ada label “serangan naik/turun” dari hitungan sampel. |

Aturan penting: satu citra tetap hanya diasumsikan menunjukkan satu kelas sesuai proposal. Mengambil banyak citra dalam sesi **tidak** mengubah model menjadi multi-label atau estimasi area sawah. Hasil per petak tidak boleh ditafsirkan sebagai prevalensi penyakit karena pemilihan daun dapat tidak acak dan jumlah sampel kecil. Setiap klaim kondisi lahan memerlukan rancangan sampling dan validasi agronomi terpisah.

### 5.3 Kandidat tahap lanjutan A22–A24

| Modul | Bentuk yang masuk akal | Prasyarat sebelum dijadikan target implementasi |
|---|---|---|
| A22 Panduan gejala di luar cakupan | Pertanyaan manual: bagian tanaman yang bergejala, ada serangga/tanda lain, gejala tidak cocok; akhir alur menyarankan foto daun ulang atau konsultasi PPL/POPT. Rujukan pola pertanyaan gejala: [IRRI Rice Doctor](https://education.irri.org/wp-content/uploads/2022/10/RD-v2.pdf). | Validasi isi oleh ahli; redaksi jelas bahwa panduan **bukan** klasifikasi tambahan; revisi skenario uji dan cakupan Bab III. |
| A23 Rencana PHT per fase | Fase tanam dipilih petani; checklist pengamatan dan pencegahan dari sumber ilmiah/resmi yang sesuai fase. | Kurasi dan validasi sumber lokal, aturan versi, uji pengguna, tanpa dosis/merek atau keputusan pestisida otomatis. |
| A24 Mode belajar gejala | Latihan pilihan gambar/ciri gejala dengan umpan balik dan rujukan; tidak menyimpan jawaban sebagai riwayat penyakit. | Hak pakai foto contoh, label yang diperiksa ahli, pengujian pemahaman; bukan pengganti akurasi model. |

A22–A24 tercatat sebagai **roadmap**, belum menjadi syarat rilis 2.0 dan belum boleh disebut fitur aplikasi yang sudah dibangun. Jika dipilih untuk TA, proposal, metode uji, jadwal, dan instrumen SUS harus diperbarui.

## 6. Struktur informasi dan alur

```text
Periksa (beranda)
  ├─ Panduan foto → Kamera/Galeri → Pratinjau/kualitas → Periksa
  │   ├─ Hasil penyakit → Langkah awal → Semua rekomendasi → Sumber
  │   ├─ Daun tampak sehat → Pantau berkala
  │   ├─ Belum meyakinkan → Foto ulang / Baca panduan / Hubungi penyuluh
  │   └─ Gagal teknis → Coba lagi / Lihat penjelasan
  └─ Pemeriksaan terakhir (bila ada)
  └─ Pilih petak/musim (opsional) → Mulai sesi survei → Periksa daun berulang
Riwayat → Semua hasil / Petak → Musim → Sesi survei → Timeline → Detail
        └─ Foto/Bagikan ringkasan/Hapus
Edukasi → 4 kelas → Gejala/Pembeda/Pencegahan/Sumber
Pengaturan → Tampilan/Data/Tentang dan detail model
```

Navigasi utama empat tujuan: **Periksa, Riwayat, Edukasi, Pengaturan**. Petak, musim, survei, dan timeline menjadi subalur Periksa/Riwayat, bukan tab utama tambahan. Statistik ditempatkan dalam Riwayat; panduan foto ditempatkan dekat CTA. Pengguna baru dapat memindai tanpa membuat petak. Tab utama tidak menggandakan layar hasil. Tombol Back dari hasil kembali ke pratinjau atau beranda secara terduga, tanpa mengulang inferensi. Untuk foto ulang, pengguna memilih sumber lagi. Setelah aplikasi dibuka ulang, layar awal tetap Periksa.

### 6.1 Wireframe teks

```text
PERIKSA                     [Status: siap offline]
Periksa daun padi
Ambil foto satu daun; hasil awal langsung di ponsel.
[ Ambil foto daun ]
[ Pilih dari galeri ]       Panduan foto
Pemeriksaan terakhir (jika ada)
Periksa | Riwayat | Edukasi | Pengaturan

HASIL: Blas daun [indikasi awal]
[foto]  Keyakinan model: 82% [? artinya]
Yang dapat dilakukan sekarang: 1. Pisahkan/pantau area bergejala ...
[ Lihat semua langkah ] [ Foto ulang ]
Detail model dan empat skor (terlipat)
```

Angka dan kalimat contoh pada wireframe bukan keluaran uji atau resep final. Semua pesan tindakan wajib berasal dari basis pengetahuan yang sudah ditinjau.

### 6.2 Spesifikasi layar dan keadaan

| Layar | Konten utama | CTA dan respons | Keadaan khusus |
|---|---|---|---|
| Periksa | Judul, kamera, galeri, panduan, status model | CTA kamera dominan, tap feedback segera | Model menyiapkan/gagal; izin kamera ditolak; riwayat kosong |
| Panduan | Contoh framing satu daun, cahaya, fokus, gejala jelas | “Saya siap memotret” | Tanpa izin kamera tetap bisa pilih galeri |
| Pratinjau | Foto lokal, crop opsional, pernyataan “ini daun padi” | Periksa, foto ulang | File rusak, rotasi EXIF, kualitas rendah, pembatalan |
| Memproses | Foto dan status singkat | Batalkan jika belum memulai inferensi; cegah tap ganda | Proses lama/gagal, aksesibilitas live announcement |
| Hasil | Nama kelas atau status belum meyakinkan, keyakinan dijelaskan, langkah pertama | Lihat rekomendasi, foto ulang | Sehat, <70%, foto buruk, DB/model gagal; hasil tidak boleh menampilkan resep yang salah |
| Rekomendasi | Kelompok kultur teknis, hayati, kimia; sumber dan keterbatasan | Buka sumber lokal/identitas publikasi, kembali | Tidak ada konten → penjelasan dan rujuk PPL |
| Riwayat/detail | Foto, tanggal, label, status, cari/filter, detail yang disimpan | Buka detail, hapus, ekspor | Data lama tanpa probabilitas, foto hilang, ribuan baris |
| Petak dan musim | Nama petak, musim aktif/selesai, jumlah pemeriksaan tersimpan | Buat/buka petak, mulai survei | Petak kosong, nama sama, pemeriksaan tanpa petak |
| Sesi survei | Jumlah foto, hasil tiap daun, belum meyakinkan/gagal | Periksa daun berikutnya, jeda/akhiri sesi | Foto dibatalkan, aplikasi ditutup, sesi belum selesai |
| Timeline petak | Urutan kunjungan dan hasil per musim | Buka pemeriksaan/sesi | Filter kosong, data lama, rentang waktu panjang |
| Edukasi | Kartu tiga penyakit + sehat; gejala dan tindakan umum | Buka detail | Konten tidak mengklaim foto telah dipindai |
| Pengaturan | Tema, privasi, ekspor/hapus, tentang | Pilih, konfirmasi | Penyimpanan hampir penuh, ekspor gagal, model tidak valid |

### 6.3 Bahasa hasil

- Gunakan “**indikasi awal**” atau “**model memperkirakan**”, bukan “diagnosis pasti”. “Keyakinan model” adalah skor softmax; ia **bukan peluang klinis terkalibrasi** atau tingkat keparahan.
- R5: “**Hasil belum meyakinkan**. Foto ulang satu daun padi dengan cahaya cukup.” Jangan menyatakan “foto ini bukan daun padi” hanya karena skor <70%.
- Skor ≥70% pada gambar luar-domain tetap bisa salah tinggi. A04 hanya menyaring kualitas teknis, tidak membuktikan objek padi. Jika pengguna ragu, berikan foto ulang dan hubungi penyuluh.
- Daun sehat berarti “**tidak tampak gejala dari tiga penyakit yang dikenali model pada foto ini**”, bukan tanaman bebas semua penyakit.
- Jangan tampilkan rekomendasi kimia jika tidak ada kelas teridentifikasi yang sah; jangan menganggap hasil rendah sebagai negatif.

## 7. Kebutuhan fungsional dan aturan penerimaan

| ID | Kebutuhan | Kondisi penerimaan yang dapat diuji |
|---|---|---|
| F-01 | Kamera | Foto yang disetujui tampil pada pratinjau; izin ditolak → penjelasan dan pilihan galeri; batal → tidak ada baris riwayat |
| F-02 | Galeri | JPEG/format yang dapat di-decode tampil; berkas rusak → pesan dan pilih ulang |
| F-03 | Offline | Mode pesawat: input, inferensi, hasil, rekomendasi, riwayat, edukasi berjalan; tidak ada request jaringan |
| F-04 | Hasil/skor | Empat label terpetakan tepat, skor kelas teratas 0–100% terlihat; detail empat skor hanya jika pengguna membuka |
| F-05 | Rekomendasi | R1–R3 mengarah ke penyakit cocok; R4 ke pemeliharaan; sumber per butir; tidak ada merek/dosis |
| F-06 | Ketidakpastian | Skor top <0,70 memicu R5, tidak menampilkan diagnosis atau tindakan kimia; foto ulang tersedia |
| F-07 | Riwayat | Setelah inferensi berhasil, satu entri tersimpan; detail tetap dapat dibuka setelah restart; penghapusan tidak menyisakan foto yatim |
| F-08 | Edukasi | Empat kelas dan sumber dapat dibuka offline tanpa riwayat |
| X-01 | Kualitas foto | Peringatan kualitas beralasan; pengguna dapat memilih ulang atau lanjut dengan status peringatan; tidak ada klaim deteksi non-padi |
| X-02 | Provenance | Jenis model “asli penulis” atau “replikasi lokal” dan hash benar, tidak saling tertukar |
| X-03 | Audit hasil | Setiap hasil baru menyimpan empat skor, top label, status, aturan, model hash, waktu dan tahap pemrosesan |
| X-04 | Migrasi | Data lama terbaca; nilai yang tidak pernah dicatat diberi `unknown`, bukan dibuat-buat |
| X-05 | Ekspor | Hanya setelah tindakan eksplisit; file memuat tanggal/kelas/status/skor dan metadata model yang tersedia; foto terpisah opsional |
| X-06 | Petak/musim | Membuat petak dan musim, menandai musim selesai, mengelompokkan hasil; scan tanpa petak tetap tersedia |
| X-07 | Sesi survei | Beberapa foto satu-daun disimpan sebagai hasil terpisah dalam satu sesi; jeda/lanjut dan ringkasan hitungan benar |
| X-08 | Timeline | Menampilkan hasil per petak dan musim secara kronologis; tidak mengubah hitungan sampel menjadi klaim prevalensi/keparahan |

Aturan R1–R5 dan ambang 70% dipertahankan sesuai proposal. Bila ambang diubah setelah validasi, revisi proposal, konfigurasi, nomor versi aturan, pengujian, dan laporan. `RuleEngine` saat ini memetakan kelas asing ke R3; ini harus menjadi galat kontrak, bukan rekomendasi bercak cokelat.

## 8. Kontrak model Mustofa dan batas klaim kesetaraan

### 8.1 Fakta jurnal yang dapat dipakai [J]

| Komponen | Spesifikasi yang dilaporkan |
|---|---|
| Data | 6.180 JPEG RGB 224×224; empat kelas 1.545 per kelas |
| Split | Stratified 70/15/15, `random_state=42`; 4.324 / 928 / 928, masing-masing kelas 1.081 / 232 / 232 |
| Masukan | Resize 224×224, rescale `1/255` ke [0,1] |
| Augmentasi | Data latih saja: rotasi ±40°, shift ±25%, zoom 0,75–1,25, flip H/V, shear 20%, channel shift ±10%, brightness 0,7–1,3 |
| Arsitektur | MobileNetV2 bobot ImageNet, `include_top=False`; GAP → BatchNorm → Dropout 0,5 → Dense 256 → BatchNorm → Dropout 0,3 → Dense 4 softmax |
| Pelatihan | Head dengan basis dibekukan; fine-tune 20 layer terakhir; Adam lr 1e-4, batch 32; maksimum 30 epoch dilaporkan, EarlyStopping patience 3 dan best checkpoint |
| Hasil penulis | Test accuracy 97,20% dari 928 citra; precision 97,30%, recall 97,09%, F1 97,19%, AUC 99,72%; TFLite 2,71 MB |
| Latensi jurnal | 144,80 ms rata-rata pada CPU Intel Core i3 gen-10/RAM 8 GB; **bukan benchmark Android** |

Paper tidak menyertakan file bobot, manifest hash/split yang lengkap, versi framework, semua pilihan loss/aktivasi Dense 256, detail konversi, atau urutan file sumber untuk mengulangi split identik. Karena itu kesetaraan bit-per-bit, split persis, dan angka akurasi persis tidak dapat diturunkan dari PDF saja.

### 8.2 Audit artefak sekarang [L]

| Butir | Jurnal | Lokal | Implikasi |
|---|---:|---:|---|
| Split train/val/test | 4.324/928/928 | 4.326/927/927 | Tidak identik; 927 hasil lokal tidak boleh dibandingkan seolah set uji yang sama |
| Durasi pelatihan | Maksimum 30 epoch dilaporkan | 19 + 19 epoch; batas skrip 30 + 30 | Perlu meluruskan jadwal fase dan batas global sebelum mengklaim replikasi ketat |
| Akurasi FP32 | 97,20% | 98,274% pada 927 citra | Hasil lokal, belum menjamin kesetaraan atau generalisasi |
| Akurasi TFLite | Tidak dilaporkan sebagai angka uji terpisah | 98,166% pada 927 citra | Hasil lokal CPU; belum bukti evaluasi Flutter/Android |
| Ukuran TFLite | 2,71 MB | 2.847.440 byte ≈2,85 MB desimal | Artefak berbeda; jangan sebut model asli |
| Konversi | Detail optimisasi tidak disebut | `Optimize.DEFAULT` [ASUMSI] | Dapat mengubah ukuran/numerik; perlu dokumentasi |
| Aktivasi Dense 256 | Tidak disebut | ReLU [ASUMSI] | Bukan kecocokan yang dapat dipastikan |
| Loss | Tidak disebut | categorical crossentropy [ASUMSI] | Dokumentasikan |
| Konfigurasi augmentasi | Shear 20% tertulis | `shear_range=0.2` | Unit semantik perlu diperiksa; jangan otomatis menganggap sama |
| Dataset | 1.545 per kelas | 1.545 per kelas | Jumlah sesuai, identitas tiap file belum dibuktikan sama dengan yang dipakai penulis |

**Risiko kebocoran [L]:** 1.105 nama file lokal berakhiran `_augN`. Audit nama dasar menunjukkan **451 keluarga citra** memiliki anggota pada lebih dari satu split dalam CSV saat ini: 207 train+test, 200 train+val, 30 test+val, dan 14 di ketiganya. Ini tidak otomatis membuktikan semua pasangan identik secara visual atau bahwa penulis jurnal melakukan hal sama. Ini bukti cukup untuk menahan klaim akurasi generalisasi dari split lokal sampai asal-usul varian diperiksa. Jangan menghapus atau mengubah dataset asli demi memperoleh skor tertentu.

### 8.3 Jalur mencapai kesetaraan yang dapat dibuktikan

**Jalur A — paling sesuai permintaan “sama persis”:** minta berkas `.tflite` atau checkpoint asli kepada penulis beserta urutan label, preprocessing, versi TensorFlow, dan manifest 928 file uji. Simpan immutable dan catat SHA-256. Verifikasi bentuk tensor `[1,224,224,3]` dan `[1,4]`, dtype, kuantisasi, label, 10–20 golden images dengan empat skor toleransi numerik, lalu bandingkan CPU TFLite vs Android. Jika artefak asli diperoleh, aplikasi memakai artefak itu dan mencatat perubahan versi. Hasil uji Android dilaporkan terpisah dari 97,20% jurnal.

**Jalur B — bila bobot asli tidak tersedia:** lakukan replikasi metode yang transparan. Bekukan dataset sumber dan hash per file; inventarisasi varian `_augN`; rekonstruksi split 4.324/928/928 dan kelompokkan keluarga sebelum pemisahan untuk uji kebocoran, sambil menyatakan bahwa split kelompok ini **berbeda dari prosedur persis jurnal** jika jurnal memang membagi file individual. Jalankan dua evaluasi terpisah: (1) rekonstruksi terdekat metode jurnal untuk pembandingan yang jujur, (2) split bebas keluarga untuk estimasi lebih konservatif. Jangan memilih salah satu skor setelah melihat hasil sebagai angka utama tanpa protokol pra-registrasi. Bandingkan arsitektur, parameter, preprocessing, inferensi, dan ukuran; semua asumsi di Bab III. Pertahankan model saat ini sebagai baseline, jangan diam-diam menggantinya.

**Jalur C — artefak tidak tersedia dan spesifikasi kritis tidak dapat dipastikan:** nyatakan “replikasi berdasarkan rincian yang tersedia”, sertakan tabel deviasi, hentikan klaim “identik”. Ini tetap dapat memenuhi tujuan aplikasi bila proposal dan pembimbing menerima penggunaan model replikasi yang terdokumentasi.

**Gerbang rilis model:** (1) provenance tercatat, (2) hash model aset cocok manifest, (3) kontrak shape/dtype/label gagal tertutup bila tidak cocok, (4) preprocessing Flutter vs Python diuji pada golden images dengan toleransi yang ditetapkan, (5) confusion matrix dan per-kelas dihitung pada set yang terdaftar, (6) uji foto lapangan terpisah melaporkan lokasi/perangkat/kondisi tanpa mencampur dengan angka jurnal, (7) Android offline dan latensi diuji. Target ≥90% proposal diuji pada denominator yang ditetapkan; hasil di bawah target dilaporkan dan dianalisis, bukan diperbaiki melalui data uji.

### 8.4 Ambang 70% dan validasi foto luar-domain

70% adalah nilai awal aturan aplikasi [P], bukan parameter arsitektur Mustofa [J]. Uji ambang pada data validasi yang tidak pernah dipakai untuk memilih model, laporkan cakupan hasil dan kesalahan per kelas; jangan memilih ambang dari set uji final. Untuk non-padi, foto multi-daun, hama, dan gejala di luar empat kelas, susun set tantangan terpisah. Laporkan *false acceptance* dan contoh kegagalan. Tanpa model/validasi luar-domain yang sah, UI tidak boleh menjamin bisa menolak foto non-padi. Pemeriksaan kualitas blur/cahaya adalah heuristik UX, bukan klasifikasi objek baru.

## 9. Arsitektur aplikasi yang diusulkan

```text
presentation: screens + reusable widgets + state controller
      ↓
domain: check-use-case, result policy R1–R5, recommendation policy
      ↓
data: inference adapter | local knowledge repository | history repository
      ↓
TFLite/model+labels | bundled knowledge JSON/SQLite | SQLite+private photos
```

Struktur folder yang disarankan untuk migrasi bertahap:

```text
lib/
  app/                 app shell, routes, dependency composition
  core/                theme, accessibility, errors, logging, file utilities
  features/check/      capture, preview, quality, preprocessing, inference, result
  features/knowledge/  disease information, recommendation rules, citations
  features/history/    records, search, export, deletion, statistics
  features/fields/     plots, seasons, survey sessions, timeline
  features/settings/   theme, privacy, provenance, about
  data/local/          SQLite migrations and image storage
assets/models/          immutable model, labels, manifest
assets/data/            versioned knowledge base and sources
test/                   unit, widget, migration and golden inference tests
integration_test/       offline device journeys
docs/evidence/          test protocols/results, no private farmer photos
```

Tidak wajib menambah state-management package. Mulai dengan controller/repository yang dapat diuji; pilih package hanya bila jumlah state lintas layar menuntutnya. Proses decode/resize yang mahal sebaiknya keluar dari UI isolate bila pengukuran menunjukkan jank. Waktu **inferensi murni** dan waktu **end-to-end** dicatat terpisah. Semua data pribadi dan foto disimpan privat di perangkat; jaringan tidak diperlukan.

### 9.1 Model data dan migrasi SQLite v1→v2

| Entitas | Kolom minimum baru | Aturan |
|---|---|---|
| `scan` | id, `photo_path`, created_at UTC+offset, `status`, `top_class`, `top_score`, `scores_json`, `rule_id`, `model_sha256`, `model_version`, `preprocess_version`, `inference_ms`, `end_to_end_ms`, `quality_flags_json`, optional notes | Satu hasil final per konfirmasi; null boleh untuk data v1 yang tidak memiliki nilai |
| `disease` | id, nama, nama ilmiah, penyebab, gejala, `content_version` | Empat kelas tetap; label UI dipisah dari label model |
| `recommendation` | id, disease_id, `category` (prevention/cultural/biological/chemical/escalation), body, source_id, order, `content_version` | Sumber per butir; tanpa merek/dosis |
| `source` | id, penulis/lembaga, judul, tahun, DOI/URL opsional, tanggal telaah | Semua konten yang ditampilkan bisa ditelusuri |
| `model_manifest` (asset atau tabel) | asal, status bobot, SHA-256, label order, input/output shape/dtype, normalisasi, tanggal build | Tidak mengubah klaim model pada riwayat lama |
| `plot` | id, name, optional location_note, created_at | Nama petak dibuat manual; GPS tidak wajib dan tidak dipakai untuk inferensi |
| `season` | id, plot_id, name, optional planting_date/variety, status, created_at | Banyak musim per petak; selesai tidak menghapus riwayat |
| `survey_session` | id, season_id, started_at, ended_at nullable, status | Sesi dapat dijeda dan dilanjutkan; semua hasil individu tetap dapat dibuka |
| `scan` (kolom relasi tambahan) | `season_id` nullable, `session_id` nullable | Pemeriksaan lama/cepat boleh tanpa petak; foreign key dan indeks menjaga query/paging |

Migrasi membaca setiap `riwayat` v1 dan memetakan status: kelas kosong → `uncertain_legacy`; kelas dikenal → `classified_legacy`; skor/waktu/foto dipertahankan. `scores_json`, hash, latensi diberi null dan label “tidak dicatat pada versi lama”. Relasi petak/musim/sesi lama bernilai null dan tampil sebagai “Belum dikelompokkan”; pengguna boleh menghubungkannya kemudian tanpa mengubah hasil inferensi. Dalam satu transaksi, migrasikan struktur lalu verifikasi jumlah baris dan akses foto sebelum menaikkan versi DB. Jika migrasi gagal, pertahankan database v1 dan tampilkan galat yang dapat dipulihkan. Tindakan hapus menghapus baris dan foto terkait secara konsisten; penghapusan petak/musim memerlukan pilihan eksplisit antara memindahkan hasil ke “Belum dikelompokkan” atau menghapus seluruh hasil terkait. Lakukan audit foto yatim. Paging harus mengganti batas tetap 100/1.000/5.000 pada layar/ekspor agar semua data dapat diakses.

## 10. Sistem tampilan dan aksesibilitas

### 10.1 Keputusan UI/UX yang mengikat revisi

Tema visual **Catatan Lapangan**: aplikasi terasa seperti alat pemeriksaan daun, dengan foto sebagai bukti utama, judul yang bisa dipindai, nomor langkah, garis tipis, dan ruang antarkonten yang lapang. Gunakan palet Soft Sage: latar krem `#F7F5F0`, kartu putih, teks `#2C3A30`, primer `#4F7157`; gelap memakai latar `#1A1C19`, kartu `#242723`, teks `#E8E6DF`, primer `#9DBFA3`. Plus Jakarta Sans tetap lokal. Aksen sage dipakai untuk aksi/indikator, bukan hamparan hijau dekoratif.

| Layar | Hierarki yang harus tampak pertama | Aksi utama | Detail sekunder |
|---|---|---|---|
| Periksa | “Periksa daun padi”, satu kalimat, status offline bila relevan | Ambil foto daun | Galeri, panduan, pemeriksaan terakhir |
| Panduan/pratinjau | Satu daun, cahaya, fokus; foto utuh tanpa crop paksa | Periksa foto | Ambil ulang, peringatan kualitas yang bisa dijelaskan |
| Hasil | Foto, status, nama indikasi atau alasan belum meyakinkan, langkah pertama | Lihat langkah penanganan atau foto ulang | Skor empat kelas, latensi, provenance dalam disclosure |
| Rekomendasi | Tindakan kultur teknis, kemudian hayati, bahan aktif, dan kapan minta bantuan | Lakukan langkah awal/baca langkah berikut | Sumber per butir dan batasan rekomendasi |
| Riwayat | Foto kecil, hasil/status, tanggal; cari/filter | Buka hasil | Statistik lokal, ekspor, hapus |
| Petak/musim | Nama petak dan musim aktif, jumlah pemeriksaan | Buka petak atau mulai survei | Riwayat tanpa petak tetap dapat diakses |
| Sesi survei | Progres jumlah daun diperiksa, hasil masing-masing | Periksa daun berikutnya | Jeda, akhiri, ulang foto; tanpa skor penyakit gabungan |
| Timeline petak | Urutan pemeriksaan per musim | Buka sesi/hasil | Tanggal dan label jelas; tanpa label “serangan naik/turun” |
| Edukasi | Tiga penyakit + daun tampak sehat, pembeda gejala | Buka kelas | Sumber, penyebab, pencegahan |
| Pengaturan | Tampilan, data saya, tentang | Ubah pilihan yang dipilih | Hapus di area terpisah; detail model dalam Tentang |

Navigasi utama tepat empat tujuan: **Periksa, Riwayat, Edukasi, Pengaturan**. Statistik masuk Riwayat; panduan berada dekat kamera. Bottom bar selalu berlabel dan aman dari system gesture. Satu tombol utama per layar. Keadaan hasil mencakup terklasifikasi, sehat, belum meyakinkan (<70%), foto perlu diulang, dan gagal teknis; tiap keadaan punya tindakan berikutnya. Detail probabilitas tertutup awalnya; bila dibuka, semua batang memakai skala 0–100% yang sama. Teks hasil menyebut “indikasi awal” dan “keyakinan model”, tanpa menjanjikan kepastian diagnosis.

### 10.2 Aturan anti tampilan generik dan gerbang UI

Jangan gunakan hero pemasaran, gradien hijau neon, glassmorphism, blob acak, kartu berbayang tebal, emoji sebagai ikon, stok foto tak bersumber, atau grafik/statistik yang mendominasi beranda. Jangan menaruh label “AI-powered” sebagai isi utama. Fotografi nyata hanya dipakai jika sumber/izin jelas; foto pengguna tidak menjadi latar teks. Ikon dari satu keluarga Material dan gaya yang konsisten. Bayangan ringan hanya untuk kedalaman yang perlu; sisanya border tipis. Tombol memiliki normal/pressed/disabled/loading/focus state. Galat menyebut penyebab yang dipahami dan langkah pemulihan, bukan stack trace atau path aset.

Untuk desain awal, gunakan grid 4/8 dp, tepi ponsel 16 dp, kartu radius 16 dp, teks isi 16 sp dengan line-height sekitar 1,5. Judul halaman sekitar 26 sp dan hasil 30 sp; semua ukuran dapat membungkus saat skala teks 200%. Foto pratinjau memakai `BoxFit.contain`. Uji 320/360/375 dp, lanskap, tablet, TalkBack, reduced motion, serta kedua tema sebelum SUS. Spesifikasi layar, wireframe, token rinci, dan state komponen ada di [dokumen UI/UX](./UI-REDESIGN-PADI-SCAN-2.0.md).

- Android phone-first. Minimum lebar uji 360–375 dp, juga 320 dp bila tersedia; tablet dan lanskap memakai batas lebar baca, bukan stretching penuh. Gunakan `LayoutBuilder` sesuai constraint.
- Pertahankan token Soft Sage yang terverifikasi kontras. Saat revisi, periksa teks normal ≥4,5:1 dan ikon/kontrol bermakna ≥3:1 pada tema terang serta gelap. Hindari hijau cerah dan latar penuh warna sesuai preferensi terdahulu pengguna.
- Plus Jakarta Sans dibundel lokal; teks isi minimal 16 sp, line-height kira-kira 1,5, tidak dipotong saat skala font 200%. Ukuran/spacing mengikuti 4/8 dp; target interaktif Android ≥48×48 dp.
- Satu CTA dominan per layar; tombol kamera terlihat tanpa menggulir pada layar umum. Hasil mendahulukan nama, arti, tindakan; probabilitas empat kelas dan latensi berada di panel terbuka atas permintaan.
- Material vector icon konsisten, dekorasi dikeluarkan dari pohon semantik. Semua status bermakna punya teks, bukan warna saja. Fokus TalkBack mengikuti urutan tampilan; status memproses/galat diumumkan; reduced motion dihormati.
- Setiap tindakan mempunyai pressed/disabled/loading/success/error state. Hindari spinner yang berkedip pada inferensi sangat singkat; jika proses berlangsung lama, tampilkan status yang stabil dan dapat diakses.
- Bottom navigation dan CTA menghormati safe area; konten gulir tidak tertutup keyboard atau bilah. Uji layar kecil, teks terbesar, lanskap, mode gelap, TalkBack, serta tanpa jaringan.

Rekomendasi UI didasarkan pada pencarian lokal `ui-ux-pro-max` untuk Flutter responsive/semantics dan pemulihan galat. Generator design-system umum menghasilkan pola pemasaran, hijau cerah, Fira Code, dan animasi web; bagian itu tidak diterapkan karena konteksnya aplikasi Flutter lapangan dan preferensi Soft Sage yang telah dicatat.

## 11. Keamanan data dan kebijakan rekomendasi

Foto hasil pemeriksaan hanya berada pada penyimpanan privat aplikasi. Beranda/pengaturan menjelaskan bahwa uninstall dapat menghapus data. Ekspor/berbagi harus dipicu pengguna, dengan pratinjau isi dan tanpa foto secara default; bila foto ikut dibagikan, tindakan itu memerlukan pilihan eksplisit. Tidak perlu izin lokasi/kontak/internet untuk fitur inti. Hindari path lengkap foto dan isi pribadi pada log rilis.

Konten rekomendasi dipisah menjadi pencegahan/kultur teknis, hayati, kimia, dan eskalasi. Kimia hanya bahan aktif/golongan tanpa merek/dosis; tampilkan keharusan mengikuti label produk terdaftar dan konsultasi penyuluh. Untuk HDB, jangan menyajikan fungisida sebagai pengobatan bakteri. Setiap butir mempunyai sumber yang dapat dibaca offline, versi konten, dan tanggal telaah. Konten biologis yang hanya terbukti di laboratorium harus dilabeli “bukti laboratorium”, bukan kepastian efektivitas lapangan. Audit agronomi oleh pembimbing atau ahli diperlukan sebelum menyatakan semua anjuran aman dan mutakhir.

## 12. Rencana uji dan bukti TA

| Lapisan | Skenario | Bukti/gerbang |
|---|---|---|
| Unit | Mapping label, shape/dtype, preprocess golden input, R1–R5 termasuk kelas asing, sumber rekomendasi, validasi NF-05 | Semua pengujian bermakna lulus |
| Widget | Periksa/pratinjau/hasil sehat-penyakit-rendah-gagal, riwayat kosong/foto hilang, font besar dan tema | Tidak ada overflow dan aksi dapat ditemukan |
| Integrasi Android | Kamera/galeri, mode pesawat, restart aplikasi, izin ditolak, DB migrasi, hapus/ekspor | Rekaman langkah dan hasil per perangkat |
| Petak dan survei | Dua petak, beberapa musim, sesi lima daun, jeda/lanjut/restart, hasil tanpa petak, penghapusan petak | Relasi dan ringkasan hitungan benar; tidak ada hasil/foto hilang tanpa tindakan eksplisit |
| Timeline | Urutan waktu, filter musim, hasil rendah/gagal, data v1 belum dikelompokkan | Semua hasil dapat dibuka; tidak ada klaim tren/tingkat serangan otomatis |
| Model | 927 data lama sebagai baseline; set uji sah baru yang ditentukan sebelumnya; confusion matrix, precision/recall/F1, cakupan R5, set tantangan luar-domain | Denominator dan manifest dipublikasikan; H4 diuji secara terpisah |
| Kinerja | 30 citra × 1–3 Android, warm-up dan jumlah thread dicatat; ukur decode/resize, `Interpreter.run`, total sejak foto siap sampai hasil | Rerata inferensi <1.000 ms per perangkat; laporkan median/p95 dan gagal |
| Usability | 10–20 petani menyelesaikan foto→hasil→rekomendasi; jika modul A19–A21 dirilis, tambahkan tugas membuat petak→survei beberapa daun→buka timeline; SUS 10 item setelah tugas | Rata-rata SUS ≥68; laporkan keberhasilan dan waktu per tugas terpisah, bukan pengganti SUS |
| Aksesibilitas | TalkBack, 200% text scale, kontras dua tema, landscape, target sentuh | Temuan kritis diperbaiki sebelum SUS |

Black-box proposal saat ini berisi B-01–B-08. Tambahkan skenario hasil tak meyakinkan, sehat, foto rusak, izin ditolak, model gagal, migrasi data, hapus/ekspor, serta X-06–X-08 untuk petak/survei/timeline sesuai fitur rilis. B-06 proposal menganggap foto non-daun akan selalu “tidak dikenali”; karena softmax empat kelas tidak menjamin hal itu, **revisi skenario menjadi uji skor <70% yang terkontrol**, dan uji non-daun sebagai challenge set terpisah dengan tingkat kegagalan terukur. Tambahan A19–A21 juga perlu tercermin dalam kebutuhan, use case, activity/sequence/class diagram, skema database, dan instrumen tugas SUS pada Bab III sebelum pengujian final.

Definisikan “waktu inferensi” sebagai waktu `Interpreter.run`, sesudah tensor masukan siap. Kode sekarang mengukur prapemrosesan **ditambah** `Interpreter.run` dengan satu `Stopwatch`, sehingga angka layar saat ini belum memenuhi definisi inferensi murni. Proposal di satu tempat menyebut “foto siap diproses hingga hasil tampil”; ukur juga metrik end-to-end itu dan jelaskan perbedaannya. Latensi 144,80 ms dari jurnal berasal dari CPU laptop. Uji HP aktual diperlukan. Tidak ada hasil Android baru yang diklaim dalam PRD ini.

## 13. Tahapan pelaksanaan dan gerbang keputusan

| Tahap | Hasil kerja | Syarat lanjut |
|---|---|---|
| 0. Penyelarasan ilmiah | Pilih jalur model A/B/C, perbaiki redaksi Bab III dan B-06, inventarisasi dataset/model | Klaim asal model disepakati dan tercatat |
| 1. Fondasi bukti | Manifest hash, golden inference, audit split/keluarga, protokol evaluasi ditetapkan | Evaluasi bebas kebocoran terpisah siap dijalankan |
| 2. Struktur & data | Controller/repository, SQLite v2, migrasi, konten rekomendasi berkategori, skema petak/musim/sesi | Data lama utuh; NF-05 lulus audit konten; relasi baru teruji |
| 3. Alur petani | Navigasi, panduan, pratinjau, hasil empat status, rekomendasi, riwayat, edukasi | F-01–F-08 dan kondisi galat lulus |
| 4. Pengamatan lapangan | Petak/musim, sesi survei beberapa daun, timeline, ringkasan jumlah sampel | Scan tunggal tetap cepat; sesi dapat dilanjutkan; tidak ada klaim prevalensi |
| 5. Poles & fitur P1 | Kualitas foto, eskalasi, pencarian, ekspor, tema, aksesibilitas | Pengujian layar kecil/gelap/TalkBack dan privasi selesai |
| 6. Evaluasi TA | Black-box termasuk modul baru, kinerja Android, akurasi terintegrasi, tugas usability tambahan dan SUS, Bab IV | Laporkan hasil apa adanya termasuk kegagalan/limitasi |

**Kondisi berhenti untuk rilis TA:** seluruh F-01–F-08 dan NF-01/NF-03/NF-04/NF-05 terverifikasi; NF-02, H4, SUS dilaporkan dengan perangkat dan sampel sah; provenance model jelas; data lama aman; rekomendasi ditinjau. Bila metrik target gagal, aplikasi tidak boleh dipresentasikan seolah lulus; jelaskan penyebab dan langkah perbaikan dalam Bab IV.

## 14. Keputusan terbuka yang memerlukan bukti

1. Apakah penulis jurnal dapat memberikan model TFLite asli, manifest split, dan versi lingkungan? Tanpa itu target bit-identik tidak dapat dibuktikan.
2. Apakah pembimbing mengizinkan pembaruan skenario B-06 dan penambahan evaluasi bebas keluarga pada Bab III? Keduanya memperbaiki validitas tanpa mengubah dataset sumber.
3. Apakah rekomendasi pertanian sudah diperiksa ahli? Terutama bahan kimia/agens hayati, konsentrasi HDB yang kini melanggar NF-05, serta perubahan pedoman setempat.
4. Perangkat Android mana yang akan dipakai untuk target <1 detik, dan apakah 10–20 petani dapat mengikuti SUS? Jangan mengisi nama perangkat atau skor sebelum uji.
5. Berapa petak, musim, dan daun per survei yang realistis untuk responden? Angka contoh lima daun hanya skenario uji perangkat lunak, bukan protokol sampling ilmiah.

### Lampiran: pemetaan ke proposal

| Proposal | PRD | Catatan |
|---|---|---|
| F-01/F-02 | A01–A03, §7 | Tambahan pratinjau tidak mengganti input foto |
| F-03, NF-01/02/03 | A05, §8, §9, §12 | Kesetaraan model dan kinerja dibuktikan terpisah |
| F-04/F-06, R1–R5 | A06, §6.3, §7, §8.4 | Label ketidakpastian diperjelas; ambang awal 70% |
| F-05, NF-05 | A07/A08, §11 | Konten dosis saat ini perlu diperbaiki |
| F-07 | A09/A10/A13/A14, §9.1 | Riwayat lokal dengan migrasi |
| Perluasan baru, belum tercantum F-01–F-08 | A19–A21, §5.2, §6, X-06–X-08, §9.1 | Petak/musim/survei/timeline perlu tambahan kebutuhan dan rancangan Bab III |
| Roadmap di luar rilis 2.0 | A22–A24, §5.3 | Panduan luar cakupan, PHT per fase, mode belajar menunggu validasi ahli dan revisi instrumen |
| F-08, NF-04 | A11/A12, §6, §10 | Edukasi Bahasa Indonesia untuk petani |
| H1–H4/SUS | §2.3, §12 | Instrumen diperluas hanya mengikuti fitur yang dirilis |

**Keterbatasan dokumen:** belum ada model asli penulis, pengujian Android baru, SUS baru, validasi agronomi, atau inspeksi visual seluruh foto. PRD ini spesifikasi pekerjaan dan audit bukti yang tersedia, bukan hasil akhir Bab IV.
