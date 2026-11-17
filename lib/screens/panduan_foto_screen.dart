import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../widgets/komponen.dart';

/// Panduan pengambilan foto (pendukung F-01 dan F-02).
///
/// Tujuan layar ini menjaga kualitas masukan model. Citra yang diambil
/// terlalu jauh, terlalu gelap, atau berlatar ramai menurunkan keyakinan
/// keluaran sehingga hasil bisa jatuh di bawah ambang batas 70%.
class PanduanFotoScreen extends StatelessWidget {
  const PanduanFotoScreen({super.key});

  static const _langkah = <(IconData, String, String)>[
    (
      Icons.straighten_rounded,
      'Jarak 15-25 cm',
      'Seluruh daun yang diamati masuk bidang gambar. Terlalu jauh membuat '
          'ciri bercak tidak terbaca model.',
    ),
    (
      Icons.wb_sunny_outlined,
      'Cahaya cukup, tanpa bayangan tajam',
      'Gunakan cahaya alami. Hindari memotret di bawah bayangan tubuh atau '
          'pada malam hari.',
    ),
    (
      Icons.center_focus_strong_rounded,
      'Fokus pada bagian bergejala',
      'Bidik tepat pada bercak, garis kebasahan, atau perubahan warna daun.',
    ),
    (
      Icons.blur_off_rounded,
      'Hindari gambar buram',
      'Tahan ponsel dengan mantap atau bersandar pada benda kokoh sebelum '
          'menekan tombol potret.',
    ),
    (
      Icons.crop_free_rounded,
      'Satu daun, satu latar',
      'Hindari latar ramai, tanah, atau daun lain yang ikut terpotret.',
    ),
  ];

  static const _hindari = <String>[
    'Memotret daun melalui layar komputer atau cetakan.',
    'Memakai filter, zoom digital maksimum, atau efek warna.',
    'Mengambil gambar dari jarak lebih dari 50 cm.',
    'Menggunakan gambar hasil tangkapan layar aplikasi lain.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panduan Ambil Foto')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          Text('Supaya hasil akurat', style: context.teks.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Model MobileNetV2 membaca citra 224 x 224 piksel. Kualitas foto '
            'menentukan tingkat keyakinan yang dihasilkan, sehingga hasil di '
            'bawah 70% tidak akan diberi diagnosis.',
            style: context.teks.bodyMedium?.copyWith(
              color: context.palet.mutedForeground,
            ),
          ),
          const SizedBox(height: AppSpacing.md + 2),
          for (final (ikon, judul, isi) in _langkah)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: context.palet.primary.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppRadius.kecil - 2,
                            ),
                          ),
                          child: Icon(
                            ikon,
                            color: context.palet.primary,
                            size: AppIkon.sedang,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm + 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(judul, style: context.teks.titleSmall),
                            const SizedBox(height: 2),
                            Text(isi, style: context.teks.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          KartuPesan(
            warna: context.palet.destructive,
            ikon: Icons.block_rounded,
            judul: 'Hindari',
            isi: _hindari.map((e) => '- $e').join('\n'),
          ),
        ],
      ),
    );
  }
}
