import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Kartu foto daun dengan sudut membulat dan tanda alternatif bila berkas
/// tidak dapat dibaca.
class KartuFoto extends StatelessWidget {
  const KartuFoto({
    super.key,
    required this.path,
    this.labelSemantik = 'Foto daun',
    this.aspectRatio = 4 / 3,
  });

  final String path;
  final String labelSemantik;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: labelSemantik,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.besar),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: ImageFile(path: path),
        ),
      ),
    );
  }
}

/// Pembungkus `Image.file` dengan penanganan galat.
///
/// Dipisah agar berkas rusak atau terhapus tidak memunculkan kotak merah,
/// melainkan pesan yang dapat dibaca pengguna.
class ImageFile extends StatelessWidget {
  const ImageFile({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.ukuranIkonGalat = 40,
  });

  final String path;
  final BoxFit fit;
  final double ukuranIkonGalat;

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(path),
      fit: fit,
      errorBuilder: (_, _, _) => ColoredBox(
        color: context.palet.muted,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: ukuranIkonGalat,
                  color: context.palet.mutedForeground,
                ),
              ),
              if (ukuranIkonGalat > 20) ...[
                const SizedBox(height: AppSpacing.sm),
                Text('Foto tidak dapat dibuka', style: context.teks.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Lencana status berlabel teks.
///
/// Aturan desain "Color is not the only indicator": warna tidak pernah
/// menjadi satu-satunya penanda status, sehingga lencana selalu memuat
/// kata dan tidak pernah hanya berupa titik berwarna.
class Lencana extends StatelessWidget {
  const Lencana({
    super.key,
    required this.teks,
    required this.warna,
    this.ikon,
  });

  final String teks;
  final Color warna;
  final IconData? ikon;

  @override
  Widget build(BuildContext context) {
    final gelap = Theme.of(context).brightness == Brightness.dark;
    final latar = Color.alphaBlend(
      warna.withValues(alpha: gelap ? 0.26 : 0.14),
      context.palet.card,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(AppRadius.pil),
        border: Border.all(color: warna.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ikon != null) ...[
            Icon(ikon, size: 14, color: warna),
            const SizedBox(width: 5),
          ],
          Text(
            teks,
            style: TextStyle(
              fontFamily: AppTheme.keluargaFont,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: warna,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu pesan bernada (informasi, peringatan, galat, keberhasilan).
///
/// [ikon] ditandai dekoratif bagi pembaca layar karena teks di sebelahnya
/// sudah menyampaikan maksud yang sama.
class KartuPesan extends StatelessWidget {
  const KartuPesan({
    super.key,
    required this.judul,
    required this.isi,
    required this.warna,
    required this.ikon,
    this.aksi,
    this.margin = EdgeInsets.zero,
  });

  final String judul;
  final String isi;
  final Color warna;
  final IconData ikon;
  final Widget? aksi;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final gelap = Theme.of(context).brightness == Brightness.dark;
    final latar = Color.alphaBlend(
      warna.withValues(alpha: gelap ? 0.16 : 0.085),
      context.palet.card,
    );

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(AppRadius.sedang),
        border: Border.all(color: warna.withValues(alpha: 0.38)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(ikon, color: warna, size: AppIkon.besar),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: context.teks.titleSmall?.copyWith(color: warna),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(isi, style: context.teks.bodyMedium),
                if (aksi != null) ...[
                  const SizedBox(height: AppSpacing.sm + 2),
                  Align(alignment: Alignment.centerLeft, child: aksi!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu bagian bernomor, dipakai pada urutan rekomendasi.
class KepalaBagian extends StatelessWidget {
  const KepalaBagian({
    super.key,
    required this.nomor,
    required this.judul,
    this.keterangan,
  });

  final String nomor;
  final String judul;
  final String? keterangan;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.palet.primary,
                    borderRadius: BorderRadius.circular(AppRadius.kecil - 4),
                  ),
                  child: Text(
                    nomor,
                    style: TextStyle(
                      fontFamily: AppTheme.keluargaFont,
                      color: context.palet.onPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(child: Text(judul, style: context.teks.titleMedium)),
            ],
          ),
          if (keterangan != null) ...[
            const SizedBox(height: AppSpacing.xs + 2),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Text(keterangan!, style: context.teks.bodySmall),
            ),
          ],
        ],
      ),
    );
  }
}

/// Keadaan kosong atau galat, dengan ikon, judul, pesan, dan aksi opsional.
class KeadaanKosong extends StatelessWidget {
  const KeadaanKosong({
    super.key,
    required this.ikon,
    required this.judul,
    required this.pesan,
    this.aksi,
  });

  final IconData ikon;
  final String judul;
  final String pesan;
  final Widget? aksi;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.palet.muted,
                shape: BoxShape.circle,
              ),
              child: ExcludeSemantics(
                child: Icon(
                  ikon,
                  size: 32,
                  color: context.palet.mutedForeground,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              judul,
              textAlign: TextAlign.center,
              style: context.teks.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              pesan,
              textAlign: TextAlign.center,
              style: context.teks.bodyMedium?.copyWith(
                color: context.palet.mutedForeground,
              ),
            ),
            if (aksi != null) ...[const SizedBox(height: AppSpacing.lg), aksi!],
          ],
        ),
      ),
    );
  }
}

/// Label–nilai satu baris untuk daftar catatan teknis.
class BarisLabelNilai extends StatelessWidget {
  const BarisLabelNilai({super.key, required this.label, required this.nilai});

  final String label;
  final String nilai;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(label, style: context.teks.bodySmall),
          ),
          Expanded(
            child: Text(
              nilai,
              style: context.teks.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.palet.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu dengan judul kecil di atas isi.
class KartuBagian extends StatelessWidget {
  const KartuBagian({
    super.key,
    this.judul,
    required this.anak,
    this.padding = const EdgeInsets.all(AppSpacing.md + 2),
    this.ikon,
  });

  final String? judul;
  final Widget anak;
  final EdgeInsetsGeometry padding;
  final IconData? ikon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (judul != null) ...[
              Row(
                children: [
                  if (ikon != null) ...[
                    ExcludeSemantics(
                      child: Icon(
                        ikon,
                        size: AppIkon.kecil,
                        color: context.palet.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(child: Text(judul!, style: context.teks.titleSmall)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm + 2),
            ],
            anak,
          ],
        ),
      ),
    );
  }
}
