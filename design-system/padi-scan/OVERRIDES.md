# Design System Overrides — Padi Scan (Modern Agricultural Utility)

Dokumen ini mencatat penyesuaian di atas `MASTER.md` berdasarkan spesifikasi **PRD v1.0 — Modern Agricultural Utility / Clean Agricultural Utility** (Bagian 4.2, 4.3, dan 9.1).

## 1. Palet Warna (PRD Bagian 9.1)

| Token | Hex (Terang) | Hex (Gelap) | Fungsi |
|---|---|---|---|
| Primary | `#176B4D` | `#6CC4A1` | Tombol dan aksi utama |
| Primary Dark | `#123D32` | `#BCE0CB` | Heading penting dan elemen navigasi |
| Background | `#F7F8F4` | `#121815` | Latar utama |
| Surface / Card | `#FFFFFF` | `#1B231F` | Kartu dan komponen |
| Border | `#E0E6DF` | `#2E3B34` | Batas elemen |
| Text Primary | `#17251E` | `#E9EFEA` | Teks utama |
| Text Secondary | `#56655C` (`#627168` PRD, disesuaikan sedikit untuk kontras di atas `muted`) | `#A3B2AA` | Teks pendukung ($\ge 4,5:1$) |
| Warning | `#A76516` | `#F3B359` | Kondisi perlu perhatian |
| Danger | `#B42318` | `#F97066` | Kesalahan dan penghapusan |
| Accent | `#DCE9BD` | `#2B3B24` | Penekanan ringan |

## 2. Tipografi & Skala Ukuran (PRD Bagian 9.1)

Font lokal: `PlusJakartaSans` (kompatibel metrik dengan Inter/Roboto dan dibundel offline untuk memenuhi NF-01).

| Komponen | Ukuran | Ketebalan |
|---|---|---|
| Heading utama | `26sp` | Semibold (`w600`) |
| Heading halaman | `22sp` | Semibold (`w600`) |
| Judul section | `18sp` | Semibold (`w600`) |
| Judul kartu | `16sp` | Semibold (`w600`) |
| Body | `16sp` | Regular (`w400`) |
| Teks pendukung | `14sp` | Regular (`w400`) |
| Caption | `12–13sp` | Medium (`w500`) |
| Tombol utama | `16sp` | Semibold (`w600`) |

## 3. Token Tata Letak (PRD Bagian 9.1)

- Padding horizontal halaman: `20dp` (`AppSpacing.horizontal`)
- Spacing kecil: `8dp`, sedang: `12–16dp`, section: `24dp`
- Radius kartu: `16dp`
- Radius tombol: `12dp`
- Tinggi tombol utama: `54dp` (`52–56dp`)
- Target sentuh minimum: `48 x 48dp`
