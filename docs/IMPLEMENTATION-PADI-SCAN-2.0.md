# Implementasi Padi Scan 2.0

Dokumen ini memetakan hasil implementasi ke `PRD-PADI-SCAN-2.0.md`.

## Cakupan yang diterapkan

- Shell responsif empat tujuan: Periksa, Riwayat, Edukasi, Pengaturan.
- Alur kamera/galeri → pemeriksaan kualitas → pratinjau → konfirmasi → inferensi offline.
- Pemeriksaan kualitas deterministik untuk cahaya dan potensi blur; pengguna tetap memegang keputusan foto ulang.
- Hasil sehat, terklasifikasi, dan tidak pasti; galat model ditampilkan sebagai kegagalan teknis di Periksa.
- Probabilitas absolut 0–100%, ambang 70%, aturan R1–R5, dan label asing ditolak.
- Timing prapemrosesan, inferensi model, dan total proses dicatat terpisah.
- SQLite v2 expand-only: audit riwayat, petak, musim tanam, sesi survei, dan timeline.
- Rekomendasi berjenjang, sumber per butir, eskalasi PPL/POPT, tanpa merek dagang dan dosis pestisida.
- Ekspor CSV v2 memuat status, relasi lapangan, aturan, timing, kualitas, dan versi model.
- Palet Soft Sage, Plus Jakarta Sans lokal, mode terang/gelap, target sentuh Material, serta layout sempit.

## Migrasi data

Pembukaan basis data v1 oleh aplikasi v2 hanya menambah kolom, tabel, dan indeks. Riwayat lama dipertahankan dan mendapat nilai default audit `tidak-tercatat`/`0`. Tidak ada langkah kontraksi atau penghapusan otomatis. Binary v1 tidak dijanjikan kompatibel untuk downgrade setelah database dibuka v2.

## Provenance model dan batas klaim

Artefak `padi_mobilenetv2.tflite` adalah reimplementasi lokal MobileNetV2, bukan bobot asli penulis Mustofa dkk. Manifest lengkap berada di `assets/models/model_manifest.json`.

- Jurnal: 6.180 citra; split 4.324/928/928; akurasi 97,20%.
- Lokal: split 4.326/927/927; akurasi TFLite 98,166%.
- `[ASUMSI]` Pembulatan split lokal berbeda dan harus dinyatakan di BAB III.
- Kesamaan nama arsitektur tidak membuktikan identitas bobot, pipeline, atau hasil jurnal.

## Non-goal versi ini

Fitur A22–A24, cloud sync, akun, GPS/peta, notifikasi, diagnosis di luar empat kelas, dan perubahan dataset/algoritma tidak diterapkan.

## Bukti verifikasi

Lihat `docs/superpowers/progress-padi-scan-2-0.md` untuk siklus RED→GREEN dan hasil suite. Gerbang rilis: format, seluruh test, analyze, dan debug APK.
