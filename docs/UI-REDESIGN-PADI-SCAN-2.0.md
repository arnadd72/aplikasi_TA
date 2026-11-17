# Spesifikasi Rombak Tampilan Padi Scan 2.0

**Status:** rancangan visual dan interaksi untuk PRD, belum diimplementasikan.  
**Tanggal:** 17 November 2026.  
**Induk:** [PRD Padi Scan 2.0](./PRD-PADI-SCAN-2.0.md).  
**Basis:** Flutter Android; `design-system/padi-scan/PALET-SOFT-SAGE.md`, `OVERRIDES.md`, `lib/theme/app_tokens.dart`; pencarian lokal `ui-ux-pro-max` untuk sistem desain, Flutter responsive/semantics, dan pemulihan galat.

## 1. Arah yang dipilih: Catatan Lapangan

Kesan yang dicari: alat kerja sederhana yang tenang, dapat dipercaya, dan terbaca di luar ruang. Metafor visualnya **lembar catatan pemeriksaan daun**: foto asli sebagai bukti, label besar, garis pemisah tipis, nomor langkah, ruang putih, dan warna tanaman yang diredam. Metafor itu diterapkan sebagai hierarki dan ritme, bukan ilustrasi dekoratif yang memenuhi layar.

| Prinsip | Wujud di aplikasi | Alasan |
|---|---|---|
| Foto adalah bukti | Foto pengguna besar di pratinjau/hasil; kartu penyakit memakai gambar referensi yang jelas asalnya, jika tersedia dan berizin | Pengguna perlu membandingkan daun, bukan memandang hiasan |
| Satu keputusan saat itu | Satu CTA dominan per layar; tindakan lain berupa tombol sekunder/teks | Penggunaan lapangan mengutamakan kecepatan |
| Keyakinan jujur | Judul “indikasi awal”, status dan tindakan; penjelasan skor mudah dibuka | Softmax dan ambang 70% tidak menjamin kebenaran |
| Tindakan bisa dipindai | Langkah 1/2/3 dengan kata kerja; sumber dalam detail | Rekomendasi lebih berguna sebagai tindakan singkat |
| Tenang dalam cahaya | Latar krem, teks gelap, aksen sage, permukaan putih | Selaras preferensi Soft Sage dan kontras yang sudah diuji |
| Identitas khas | Siluet satu helai daun pada logo aplikasi/empty state seperlunya; garis seperti ruas daun hanya pada header edukasi | Memberi karakter tanpa stok gambar generik |

Hindari: kartu dengan gradien hijau besar, efek kaca/blur, blob acak, bayangan tebal, emoji, ikon dari beberapa keluarga, hero marketing, statistik di beranda, slogan AI, badge “AI-powered”, animasi melayang, empat tombol sama kuat, dan persen besar seolah akurasi diagnosis. Jangan mengulang dekorasi daun di setiap kartu. Ikon Material vector yang dipakai sekarang boleh diteruskan dengan satu gaya konsisten.

## 2. Sketsa cepat tampilan

```text
┌──────────────────────────────────────┐
│ Padi Scan                     Offline │
│                                      │
│ Periksa daun padi                    │
│ Foto satu daun. Lihat indikasi awal. │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │   [ikon kamera garis sederhana]  │ │
│ │   Ambil foto daun                │ │  ← aksi paling menonjol
│ └──────────────────────────────────┘ │
│ [ Pilih dari galeri ]   Panduan foto  │
│                                      │
│ Pemeriksaan terakhir                 │
│ [foto kecil] Blas daun · 10.24   ›   │
│                                      │
│ Periksa  Riwayat  Edukasi  Pengaturan│
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│ ‹ Hasil pemeriksaan                  │
│ [foto daun, rasio tetap, bisa zoom]  │
│                                      │
│ INDIKASI AWAL                        │
│ Blas daun                            │
│ Keyakinan model 82%  [?]             │
│                                      │
│ Langkah pertama                      │
│ 1  Amati daun lain di sekitar...     │
│                                      │
│ [ Lihat langkah penanganan ]         │
│ [ Periksa foto lain ]                │
│ Detail model & empat skor        ⌄   │
└──────────────────────────────────────┘
```

Sketsa adalah hierarki, bukan desain piksel final. Teks tindakan di hasil hanya boleh memakai konten rekomendasi yang lolos audit ilmiah. Angka 82% hanya contoh layout.

## 3. Audit layar sekarang → perubahan yang diinginkan

| Layar sekarang | Masalah pengalaman | Rombakan |
|---|---|---|
| Beranda | Empat menu setara dan kartu “cara pakai” mengambil ruang dari tugas utama | Header ringkas, satu CTA foto, galeri sekunder, panduan dekat kamera, riwayat terakhir seperlunya |
| Hasil | Foto, status, grafik probabilitas, dan catatan teknis bersaing untuk perhatian | Foto + status + langkah awal dahulu; rincian angka di disclosure “Detail model” |
| Rekomendasi | Butir panjang dan hayati/kimia dicampur | Kelompok “Lakukan dulu”, “Pilihan hayati”, “Bahan aktif”, “Minta bantuan”; sumber tiap butir |
| Riwayat | Daftar padat dan kontrol filter dapat berat di layar sempit | Cari sederhana, chip filter horizontal terbatas, kartu baris foto/label/tanggal; detail tetap lengkap |
| Statistik | Beranda memberi bobot sama dengan tugas pemeriksaan | Masuk sebagai subhalaman Riwayat; label “ringkasan perangkat ini” |
| Informasi | Teks panjang tanpa orientasi visual cukup | Katalog tiga penyakit + daun sehat, masing-masing gejala/pembeda/tindakan/sumber |
| Pengaturan | Tema, ekspor, hapus, dan model tersusun seperti daftar tindakan setara | Kelompok Tampilan, Data saya, Tentang; hapus diberi pemisah dan konfirmasi |

## 4. Sistem visual konkret

### 4.1 Warna

Gunakan token Soft Sage yang ada. Jangan menyalin palet hijau terang dari `MASTER.md` ke UI baru. Warna peran, bukan dekorasi.

| Peran | Terang | Gelap | Penggunaan |
|---|---|---|---|
| Latar | `#F7F5F0` | `#1A1C19` | Seluruh layar |
| Permukaan | `#FFFFFF` | `#242723` | Kartu fokus dan sheet |
| Teks utama | `#2C3A30` | `#E8E6DF` | Judul, isi, label |
| Primer | `#4F7157` | `#9DBFA3` | CTA dan item aktif |
| Teks di primer | `#FFFFFF` | `#1A2B1F` | Label CTA |
| Teks sekunder | `#5E6B60` | `#A9B3A8` | Meta, keterangan |
| Peringatan | `#8A6A38` | `#D9B87C` | Perlu ulang/ragu, bersama teks |
| Galat | `#AA4A41` | `#E08A80` | Gagal proses, bersama teks |
| Garis | `#DCD8CE` | `#3A3E38` | Pemisah, border seperlunya |

Kontras yang tercatat di `PALET-SOFT-SAGE.md` sudah diuji pada pasangan token. Begitu warna digabung dengan opasitas, foto, scrim, atau latar lain, uji ulang pasangan aktual. Jangan menaruh teks sage tipis di atas foto. Gunakan scrim solid atau permukaan penuh di belakang teks.

### 4.2 Tipografi

Plus Jakarta Sans lokal tetap dipakai agar offline. Skala awal berikut adalah **sp Flutter** dan harus beradaptasi dengan skala teks sistem, tidak di-hardcode sebagai ukuran tinggi kartu:

| Token | Ukuran / berat | Penggunaan |
|---|---|---|
| Display hasil | 30 / 700 | Nama kelas satu atau dua baris |
| Judul halaman | 26 / 700 | “Periksa daun padi” |
| Judul bagian | 20 / 700 | “Langkah pertama” |
| Judul kartu | 17 / 600 | Riwayat, katalog |
| Isi | 16 / 400, line-height 1,5 | Semua instruksi utama |
| Meta | 14 / 500 | Tanggal, asal sumber, label status |
| Caption | 13 / 400 | Hanya detail tambahan; jangan untuk instruksi penting |

Maksimum dua keluarga bobot dominan per komponen. Hindari semua huruf kapital pada paragraf. Huruf kapital boleh untuk label kecil “INDIKASI AWAL”; pembaca layar tetap mendapat label semantik yang wajar. Jangan paksa judul satu baris; tinggi menyesuaikan teks 200%.

### 4.3 Spasi, radius, ikon, fotografi

- Grid 4/8 dp: luar ponsel 16 dp, antarkomponen 8/16, antarbagian 24/32. Lebar konten tablet maksimal sekitar 640 dp; daftar riwayat boleh dua kolom bila ruang dan teks cukup.
- Radius: tombol 12–16 dp, kartu 16 dp, foto 16 dp, sheet 20 dp. Jangan semua elemen berbentuk pill.
- Elevasi hampir nol; border tipis pada kartu biasa, elevasi ringan untuk sheet/CTA jika kontras permukaan kurang.
- Ukuran ikon semantik 20–24 dp; target tap minimum 48×48 dp. Icon-only control wajib label TalkBack.
- Foto asli memakai rasio 4:3 atau aspect ratio konten yang tidak memotong gejala; `BoxFit.contain` pada pratinjau/detail. Thumbnail boleh crop dengan indikator buka foto penuh.
- Ilustrasi tambahan hanya jika membantu instruksi kamera. Jika tidak ada foto referensi dengan hak pakai dan sumber jelas, gunakan skema vektor sederhana atau teks; jangan memakai citra dataset sebagai contoh lapangan tanpa pemeriksaan lisensi dan label.

### 4.4 Gerak dan umpan balik

Tap mendapat respons dalam 80–150 ms. Transisi layar memakai Material bawaan sekitar 200–300 ms; disclosure 150–200 ms. Matikan gerak non-esensial bila `MediaQuery.disableAnimations` aktif. Jangan animasi bar probabilitas dari 0 ke nilai yang dapat memberi kesan hasil “naik” atau berubah. Untuk inferensi cepat, hindari spinner yang berkedip; tampilkan state stabil setelah sekitar 150–250 ms bila masih berjalan. Untuk proses lama, tampilkan status yang dapat dibaca TalkBack dan opsi pemulihan.

## 5. Arsitektur navigasi dan layout per layar

### 5.1 Shell dan navigasi

- Bottom bar empat item: Periksa, Riwayat, Edukasi, Pengaturan; label selalu terlihat, aktif punya ikon terisi/indikator jelas serta teks. Area aman bawah wajib dihitung.
- Petak/musim, sesi survei, dan timeline muncul sebagai alur di dalam Periksa/Riwayat. Pengguna tetap dapat periksa satu daun tanpa membuat petak. Jangan menambah tab kelima.
- Layar detail memakai AppBar dengan Back yang bekerja. Saat pengguna kembali dari hasil ke beranda, tidak ada pemindaian ulang otomatis.
- CTA kamera ada di atas lipatan pada tinggi layar ponsel umum. Bottom bar tidak menutup tombol atau pesan.
- Pada tablet, bar bisa menjadi navigation rail bila lebih mudah, tetapi alur/label tetap sama. Tidak perlu layout dashboard.

### 5.2 Beranda Periksa

Urutan: merek kecil + status “Siap offline” → judul tugas → satu kalimat penjelasan → tombol kamera penuh lebar → galeri sekunder → link panduan → pemeriksaan terakhir bila ada. Status model hanya terlihat bila memengaruhi tindakan; jika gagal, tampilkan pesan operasional “Pemeriksaan belum bisa digunakan” dan tombol coba lagi, bukan path aset pengembang. Pengguna baru tidak melihat kartu kosong riwayat yang besar. Jangan tampilkan jumlah statistik, model hash, atau chart di beranda.

### 5.3 Panduan dan pratinjau

Panduan tiga poin: satu daun, cahaya cukup, gejala jelas/fokus. Masing-masing satu kalimat dan visual sederhana yang tidak mengambil satu layar penuh. Pratinjau menampilkan foto utuh, tombol “Periksa foto” dan “Ambil ulang”. Crop manual opsional; jika tersedia, tampilkan reset dan perubahan framing. Peringatan blur/gelap diposisikan tepat di bawah foto, menjelaskan alasan dan memberi “Ambil ulang” serta “Tetap periksa”. Ini bukan label “bukan padi”.

### 5.4 Hasil

Empat keadaan tingkat atas:

1. **Terklasifikasi:** “Indikasi awal: [penyakit]”, foto, arti skor pendek, satu langkah pertama, CTA rekomendasi.
2. **Daun tampak sehat:** “Tidak tampak gejala dari tiga penyakit yang dikenali”, foto, saran pemantauan, CTA foto lain.
3. **Belum meyakinkan:** skor <70%, tidak ada nama penyakit sebagai diagnosis, foto ulang dan panduan.
4. **Gagal teknis:** model/file/DB gagal, pesan jelas, coba lagi; jangan tampilkan hasil setengah jadi.

Rincian empat skor berada dalam “Lihat detail model” yang tertutup secara default. Bila dibuka, nama kelas berbahasa Indonesia, skor angka, dan bar skala **0–100% yang sama untuk semua kelas**; jangan skala setiap bar relatif ke skor tertinggi tanpa penjelasan. Waktu inferensi, hash model, dan versi preprocessing masuk detail lebih dalam. Skor selalu ditulis “keyakinan model” dan punya penjelasan satu kalimat bahwa itu bukan kepastian diagnosis.

### 5.5 Rekomendasi

Header foto kecil + nama indikasi, lalu daftar tindakan berurutan. Setiap butir: nomor, kata kerja, ringkasan 1–3 baris, sumber yang dapat dibuka. Kelompok terpisah: “Lakukan dulu”, “Pilihan hayati”, “Bahan aktif”, “Kapan minta bantuan”. Jangan mencampur konten hayati dan kimia dalam satu label. Jika konten terlalu panjang, ringkas dengan editor konten tanpa mengubah maksud sumber. Kimia tidak punya CTA membeli; tanpa merek dan dosis. Normal hanya pemantauan, bukan pengendalian.

### 5.6 Riwayat dan ringkasan

Baris berisi foto 56–64 dp, nama/status, tanggal lokal, disclosure. Pencarian/filtrasi ditempatkan di atas daftar tanpa memaksa pengguna memilih filter untuk melihat hasil. Detail mempertahankan foto, kelas, keyakinan, rekomendasi yang berlaku saat pemeriksaan, dan versi model bila tercatat. Data lama diberi label “detail model belum dicatat”. Ringkasan berada dalam Riwayat dan hanya menyatakan jumlah pemeriksaan lokal, bukan statistik epidemiologi.

### 5.7 Edukasi dan pengaturan

Edukasi membuka empat kelas dalam katalog. Kartu menonjolkan nama dan satu pembeda gejala, lalu detail berisi penyebab, gejala, pencegahan, sumber. Jika foto referensi dipakai, label “contoh dari dataset/literatur” jelas. Pengaturan dibagi “Tampilan”, “Data saya”, “Tentang Padi Scan”; tindakan hapus ditempatkan di akhir kelompok data dengan konfirmasi. Panel model dan provenance dapat dibuka dari Tentang; tidak dijadikan jargon di seluruh aplikasi.

### 5.8 Petak, survei, dan timeline

Di Periksa, tautan sekunder “Mulai survei petak” membuka pemilih petak dan musim. Form petak hanya mewajibkan nama; varietas/tanggal tanam/lokasi tertulis boleh kosong. Bila petak belum ada, tawarkan “Buat petak” tanpa menghalangi pemeriksaan satu foto. Dalam sesi, header menampilkan nama petak, musim, dan “3 daun diperiksa”; tombol dominan “Periksa daun berikutnya”. Setiap hasil satu daun dapat dibuka sendiri. Tombol “Jeda survei” dan “Selesai” jelas berbeda; keluar sementara tidak menghapus hasil.

Ringkasan sesi memakai label **“hasil dari daun yang diperiksa”** serta jumlah per kelas, belum meyakinkan, dan gagal. Jangan memakai diagram yang menyerupai persentase luas sawah atau label tingkat serangan. Timeline dalam detail petak mengurutkan sesi menurut tanggal, dengan filter musim dan daftar foto/hasil; tidak menampilkan grafik “penyakit naik/turun” dari sampel yang tidak terstandar. Riwayat lama tetap bisa dilihat sebagai “Belum dikelompokkan”.

## 6. Komponen bersama dan state yang wajib didesain

| Komponen | Variasi/state | Aturan |
|---|---|---|
| Primary action | normal, pressed, disabled, loading | Teks berbentuk kata kerja; min 48 dp; disabled punya alasan bila penting |
| Secondary action | outlined/text, pressed, focused | Tidak bersaing warna dengan CTA utama |
| Status banner | info, warning, error, success | Ikon + judul + alasan + langkah berikut; tidak mengandalkan warna |
| Photo panel | empty, loaded, missing, decode error | Aspect ratio stabil; alt/semantics menyebut isi/fungsi |
| Result header | disease, healthy, uncertain, failure | Satu pesan utama; skor tepat konteks |
| Step card | ringkas, expanded | Nomor dan tindakan, sumber tersedia |
| History row | legacy, current, missing image | Semantik tanggal/hasil; target tap seluruh baris |
| Disclosure | closed, open, focused | State `expanded` diumumkan; tidak menaruh informasi wajib di dalamnya |
| Dialog hapus | open, confirming, failure | Menyatakan data yang hilang dan tombol Batal jelas |

Kopi galat harus menyebut **apa yang terjadi** dan **apa yang bisa dilakukan**. Contoh: “Foto tidak bisa dibaca. Pilih foto lain.” Jangan menampilkan stack trace atau `assets/models/...` kepada petani. Detail teknis boleh tersedia dari Tentang untuk penguji.

## 7. Responsif, aksesibilitas, dan pengujian desain

| Kondisi | Hasil yang harus terlihat |
|---|---|
| 360–375 dp portrait | CTA kamera, galeri, dan panduan ditemukan tanpa layout meluber; label bottom bar terbaca |
| 320 dp atau teks 200% | Judul dan tombol membungkus; foto tidak mengecil hingga tidak berguna; konten bisa scroll |
| Landscape | Foto dan kontrol tetap terlihat; tidak ada tombol di balik system bar |
| Tablet | Lebar paragraf dibatasi; daftar boleh adaptif; navigasi tetap jelas |
| Tema gelap | Semua pasangan warna aktual diuji, termasuk banner/scrim/disabled/focus |
| TalkBack | Urutan baca: judul→foto→status→aksi; ikon dekoratif tidak dibaca ganda; error diumumkan |
| Reduced motion | Semua gerak non-esensial hilang tanpa menghilangkan status atau fokus |
| Offline/izin ditolak/model gagal | Tiap kondisi punya recovery action, tanpa dead-end |

Sebelum implementasi, buat wireframe low fidelity untuk Periksa, Pratinjau, empat keadaan Hasil, Rekomendasi, Riwayat, Petak/Musim, Sesi Survei, Timeline, Edukasi, dan Pengaturan. Uji tugas foto→hasil→rekomendasi serta tugas tambahan petak→survei→timeline pada calon pengguna/pembimbing; catat keberhasilan keduanya terpisah. Setelah implementasi, jalankan checklist native/mobile `ui-ux-pro-max`: target sentuh Android ≥48 dp, teks normal ≥4,5:1, kontrol nonteks ≥3:1, safe area, pressed/disabled/focus, font besar, TalkBack, dua tema, layar kecil/tablet/lanskap. SUS penelitian tetap dijalankan terhadap aplikasi final, bukan wireframe.

## 8. Urutan pengerjaan tampilan

1. Kunci arsitektur navigasi, copy hasil, dan status empat keadaan. Periksa keselarasan dengan PRD/Bab III.
2. Bentuk token dan komponen bersama; buat satu contoh layar Periksa + Hasil untuk menguji arah Catatan Lapangan.
3. Implementasikan alur foto dan rekomendasi, lalu Riwayat/Edukasi/Pengaturan.
4. Uji pada perangkat Android nyata, foto nyata, mode offline, ukuran teks besar, dua tema, dan TalkBack.
5. Koreksi layar yang membuat pengguna ragu atau salah tindakan, kemudian jalankan SUS final.

**Batas dokumen:** rancangan ini belum mengubah kode, belum memiliki mockup piksel, dan belum membuktikan usability. Keputusan warna/ukuran dapat disetel setelah diuji, tetapi perubahan klaim model, aturan 70%, serta isi anjuran harus mengikuti bukti dan proposal.
