# Palet "Soft Sage" — Pengganti Hijau Pekat

**Tanggal:** 16 November 2026
**Permintaan pengguna:** warna/UI dibuat lebih lembut, tidak terlalu hijau.
**Berlaku sebagai:** penyimpangan ke-6 dari `design-system/padi-scan/MASTER.md`, dicatat di `OVERRIDES.md`.

---

## 1. Alasan

Palet "Earth green + harvest gold" pada `MASTER.md` memakai hijau pekat
(`#15803D` primer, `#22C55E` sekunder, latar mint `#F0FDF4`). Di layar
pengguna terasa terlalu menyala dan terlalu "hijau". Pengguna meminta
tampilan lebih lembut.

Arah baru: **sage diredam di atas kertas krem hangat**. Hijau tetap ada
karena aplikasi bertema padi, tetapi diturunkan saturasinya dan digeser
ke arah abu-hijau. Latar pindah dari mint ke netral hangat sehingga
kesan keseluruhan lebih tenang.

---

## 2. Palet terang

| Peran | Lama | **Baru** |
|---|---|---|
| primary | `#15803D` | **`#4F7157`** |
| onPrimary | `#FFFFFF` | `#FFFFFF` |
| secondary | `#22C55E` | **`#7A9578`** |
| onSecondary | `#0F172A` | **`#1E2A22`** |
| accent | `#A16207` | **`#A8834A`** |
| onAccent | `#FFFFFF` | **`#2A1F0E`** |
| background | `#F0FDF4` | **`#F7F5F0`** |
| foreground | `#14532D` | **`#2C3A30`** |
| card | `#FFFFFF` | `#FFFFFF` |
| cardForeground | `#14532D` | **`#2C3A30`** |
| muted | `#E8F0F1` | **`#EDEAE3`** |
| mutedForeground | `#475569` | **`#5E6B60`** |
| border | `#BBF7D0` | **`#DCD8CE`** |
| destructive | `#DC2626` | **`#AA4A41`** |
| onDestructive | `#FFFFFF` | `#FFFFFF` |
| success | `#15803D` | **`#4F7157`** |
| warning | `#A16207` | **`#8A6A38`** |

## 3. Palet gelap

| Peran | Lama | **Baru** |
|---|---|---|
| primary | `#4ADE80` | **`#9DBFA3`** |
| onPrimary | `#052E16` | **`#1A2B1F`** |
| secondary | `#22C55E` | **`#7E9B84`** |
| onSecondary | `#052E16` | **`#16231A`** |
| accent | `#FACC15` | **`#D9B87C`** |
| onAccent | `#422006` | **`#2A1F0E`** |
| background | `#08170F` | **`#1A1C19`** |
| foreground | `#DCFCE7` | **`#E8E6DF`** |
| card | `#10241A` | **`#242723`** |
| cardForeground | `#DCFCE7` | **`#E8E6DF`** |
| muted | `#1B3327` | **`#2E322C`** |
| mutedForeground | `#A7C4B4` | **`#A9B3A8`** |
| border | `#23503A` | **`#3A3E38`** |
| destructive | `#F87171` | **`#E08A80`** |
| onDestructive | `#450A0A` | **`#3A1410`** |
| success | `#4ADE80` | **`#9DBFA3`** |
| warning | `#FACC15` | **`#D9B87C`** |

Perubahan kunci pada mode gelap: latar tidak lagi hijau-hitam (`#08170F`)
melainkan **arang hangat netral** (`#1A1C19`), dan kartu tidak lagi hijau
tua (`#10241A`) melainkan abu hangat (`#242723`). Efeknya layar gelap
berhenti terasa "hijau menyala".

---

## 4. Turunan ColorScheme yang ikut diubah

Berkas: `lib/theme/app_theme.dart`

| Slot | Terang baru | Gelap baru |
|---|---|---|
| primaryContainer | `#E3EAE1` | `#31402F` |
| onPrimaryContainer | `#22301F` | `#E3EAE1` |
| secondaryContainer | `#E9EDE6` | `#2E322C` |
| onSecondaryContainer | `#22301F` | `#E3EAE1` |
| tertiaryContainer | `#F4EADA` | `#3B3222` |
| onTertiaryContainer | `#2A1F0E` | `#F4EADA` |
| errorContainer | `#F6E3E1` | `#4A2420` |
| onErrorContainer | `#3A1410` | `#F6E3E1` |
| surfaceContainerLow | `#FCFAF6` | `#1E211D` |
| surfaceContainer | `#F2EFE8` | `#242723` |
| surfaceContainerHigh | `#ECE8E0` | `#2A2E28` |
| outlineVariant | `#E5E1D8` | `#2E322C` |
| inverseSurface | `#2C3A30` | `#E8E6DF` |
| onInverseSurface | `#F7F5F0` | `#1A1C19` |
| shadow | `#1A1C19` | `#1A1C19` |
| scrim | `#12140F` | `#12140F` |

SnackBar:

| Mode | Latar | Teks |
|---|---|---|
| terang | `#2C3A30` | `#F7F5F0` |
| gelap | `#E8E6DF` | `#1A1C19` |

---

## 5. Verifikasi kontras WCAG 2.1 (butir 1.4.3)

Diukur dengan `D:\TUGAS AKHIR\ml\cek_kontras.py`.

### Terang

| Pasangan | Rasio | Min | Hasil |
|---|---|---|---|
| foreground / background | 10,98 | 4,5 | OK |
| cardForeground / card | 11,97 | 4,5 | OK |
| onPrimary / primary | 5,48 | 4,5 | OK |
| mutedForeground / background | 5,14 | 4,5 | OK |
| mutedForeground / muted | 4,66 | 4,5 | OK |
| destructive / background | 5,12 | 4,5 | OK |
| onDestructive / destructive | 5,58 | 4,5 | OK |
| onSecondary / secondary | 4,54 | 4,5 | OK |
| onAccent / accent | 4,62 | 4,5 | OK |
| primary / background (non-teks) | 5,03 | 3,0 | OK |
| warning / background (non-teks) | 4,59 | 3,0 | OK |

### Gelap

| Pasangan | Rasio | Min | Hasil |
|---|---|---|---|
| foreground / background | 13,74 | 4,5 | OK |
| cardForeground / card | 12,10 | 4,5 | OK |
| onPrimary / primary | 7,39 | 4,5 | OK |
| mutedForeground / background | 7,92 | 4,5 | OK |
| mutedForeground / muted | 6,03 | 4,5 | OK |
| destructive / background | 6,63 | 4,5 | OK |
| onDestructive / destructive | 6,30 | 4,5 | OK |
| onSecondary / secondary | 5,36 | 4,5 | OK |
| onAccent / accent | 8,53 | 4,5 | OK |
| primary / background (non-teks) | 8,51 | 3,0 | OK |
| warning / background (non-teks) | 9,07 | 3,0 | OK |

**Semua lulus.** Pasangan paling mepet: `onSecondary / secondary` = 4,54
pada mode terang. Jangan menurunkan lagi `secondary` tanpa mengukur ulang.

---

## 6. Berkas yang disentuh

| Berkas | Perubahan |
|---|---|
| `lib/theme/app_tokens.dart` | `AppPalet.terang` dan `AppPalet.gelap` diganti seluruhnya |
| `lib/theme/app_theme.dart` | 16 slot `ColorScheme` + warna SnackBar kedua mode |
| `D:\TUGAS AKHIR\ml\cek_kontras.py` | **BARU** — penghitung kontras WCAG mandiri |

Tidak ada widget yang perlu diubah: seluruh layar sudah memakai token
(`context.palet`), tidak ada hex ad-hoc di `lib/screens/` atau
`lib/widgets/`. Diverifikasi dengan pencarian `Color(0x` di seluruh `lib/`
— hasilnya hanya `app_theme.dart` dan `app_tokens.dart`.

---

## 7. Bukti uji

```
flutter analyze  → No issues found!
flutter test     → 49 uji lulus
```

---

## 8. Catatan untuk BAB III

Perubahan palet ini **tidak menyentuh** F-01..F-08 maupun NF-01..NF-05.
Ia murni kosmetik dan tidak mengubah ambang 70 %, aturan R1–R5, model,
maupun dataset. Cukup dicatat sebagai penyempurnaan antarmuka pada
BAB IV (bagian perancangan antarmuka), bukan sebagai penyimpangan
metodologis.

Bila pembimbing meminta kesetiaan visual terhadap `MASTER.md`, palet
lama tetap tersimpan di riwayat dokumen ini (kolom "Lama" pada tabel
Bagian 2 dan 3) dan dapat dipulihkan hanya dengan menyalin kembali
nilai-nilai tersebut ke `app_tokens.dart`.
