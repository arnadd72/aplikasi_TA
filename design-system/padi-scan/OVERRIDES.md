# Penyimpangan dari MASTER.md — alasan dan keputusan

Berkas ini mencatat setiap penyimpangan dari
[MASTER.md](./MASTER.md), sesuai aturan skill `ui-ux-pro-max`
("MASTER.md adalah sumber kebenaran global; aturan di berkas ini
menggantikannya untuk proyek ini").

## 1. Tipografi: Fira Code + Fira Sans → Plus Jakarta Sans

**MASTER.md menetapkan:** Heading `Fira Code`, Body `Fira Sans`
(mood: *dashboard, data, analytics, code, technical, precise*).

**Keputusan:** diganti dengan **Plus Jakarta Sans** (pasangan
"Friendly SaaS" dari basis data `typography.csv`).

**Alasan:**

1. Fira Code adalah font *monospace* untuk kode. Sebagai judul pada
   aplikasi konsumen, hurufnya mengurangi keterbacaan judul berbahasa
   Indonesia yang panjang (mis. "Identifikasi Penyakit Daun Padi").
2. Mood "dashboard/data/analytics" dari hasil pencarian `--design-system`
   muncul karena kata kunci "agriculture" memetakan kategori ke
   *Agriculture/Farm Tech*. Pengguna aplikasi adalah petani, bukan analis
   data, sehingga mood yang tepat adalah *friendly, approachable, readable*.
3. Plus Jakarta Sans adalah rupa huruf Indonesia (dibuat untuk Jakarta),
   mendukung seluruh aksara Latin dengan diakritik, dan tersedia dalam
   bobot 400–800 — cukup untuk membangun hierarki tipe tanpa menambah
   keluarga font kedua.
4. Dipilih pasangan font **lokal** (bukan Google Fonts saat berjalan) agar
   NF-01 (identifikasi sepenuhnya offline) tetap terpenuhi. Tidak ada
   permintaan jaringan saat aplikasi dijalankan.

**Konsekuensi:** tidak ada `@import` Google Fonts pada aplikasi Flutter;
berkas `.ttf` disimpan di `assets/fonts/` dan didaftarkan di `pubspec.yaml`.

## 2. Mode gelap diaktifkan

**MASTER.md menyatakan:** `Mode Support: Light supported | Dark supported`,
tetapi versi awal aplikasi hanya menyediakan tema terang.

**Keputusan:** kedua mode disediakan, dengan palet terpisah.

**Alasan:** daftar periksa pradeliver menuntut pengujian kontras pada kedua
mode secara terpisah. Hijau `#15803D` dari MASTER.md hanya mencapai kontras
yang cukup di atas latar terang; di atas latar gelap nilainya diturunkan
kontrasnya sehingga memakai `#4ADE80`. Detail palet: `lib/theme/app_tokens.dart`.

## 3. Warna status ditambahkan

**MASTER.md tidak menyebut** warna *success* dan *warning* secara eksplisit;
warna Destructive ada.

**Keputusan:** dua peran tambahan pada `AppPalet`:

| Peran | Terang | Gelap | Sumber |
|---|---|---|---|
| `success` | `#15803D` | `#4ADE80` | Primary MASTER.md |
| `warning` | `#A16207` | `#FACC15` | Accent MASTER.md |

**Alasan:** layar hasil identifikasi (F-04) harus menyampaikan tingkat
keyakinan, dan aturan R5 memakai ambang 70%. Warna saja tidak boleh menjadi
satu-satunya penanda, sehingga setiap status selalu disertai teks
("Tingkat keyakinan 82,14%") dan label kata pada lencana. Palet tetap
memakai nilai dari MASTER.md, tidak mengarang warna baru.

## 4. Pola halaman tidak diikuti apa adanya

**MASTER.md menetapkan pola** *Feature-Rich Showcase* dengan urutan
Hero → Feature grid → Use cases → Social proof → CTA.

**Keputusan:** tidak diterapkan.

**Alasan:** pola itu adalah pola halaman pendaratan pemasaran. Padi Scan
adalah alat sekali pakai: pengguna membuka aplikasi, langsung memotret
daun, lalu membaca hasil. Menyisipkan bagian hero dan bukti sosial akan
menunda tindakan utama. Struktur yang dipakai tetap memenuhi prinsip
konversinya (satu pesan utama per kartu, CTA utama berulang) tanpa bagian
pemasaran.

## 5. Gerak

**MASTER.md menetapkan** *Stagger List* dengan GSAP (`back.out(1.4)`,
stagger 0,06 detik) untuk daftar grid.

**Keputusan:** tidak memakai GSAP (tidak tersedia di Flutter) dan tidak
memakai animasi masuk bertahap pada daftar.

**Alasan:** stagger `back.out` over-shoot pada daftar informasi padat
dinyatakan sendiri sebagai anti-pola oleh MASTER.md ("Don't use back.out on
dense data tables"). Daftar riwayat dan probabilitas adalah daftar
informasi padat. Sebagai gantinya dipakai transisi Material bawaan dengan
durasi dari `AppDurasi` (150/200/300 ms) dan seluruh gerak non-esensial
dinonaktifkan saat `MediaQuery.disableAnimations` bernilai benar
(padanan `prefers-reduced-motion`).

