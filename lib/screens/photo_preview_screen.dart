import 'dart:io';

import 'package:flutter/material.dart';

import '../logic/photo_quality_checker.dart';
import '../theme/app_tokens.dart';
import '../widgets/komponen.dart';

/// Layar Pratinjau Foto sesuai PRD F-03, F-04, S-04, dan S-05.
///
/// Menampilkan pratinjau foto besar dengan bingkai panduan halus,
/// instruksi pengambilan foto ("Pastikan daun terlihat jelas dan tidak buram."),
/// pemeriksaan kualitas deterministik (gelap/buram), serta tombol
/// "Gunakan foto" dan "Foto ulang".
class PhotoPreviewScreen extends StatefulWidget {
  const PhotoPreviewScreen({
    super.key,
    required this.pathFoto,
    this.kualitasAwal,
    this.pratinjau,
    this.onKonfirmasi,
  });

  final String pathFoto;
  final KualitasFoto? kualitasAwal;
  final Widget? pratinjau;
  final Future<void> Function()? onKonfirmasi;

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  KualitasFoto? _kualitas;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _kualitas = widget.kualitasAwal;
    if (_kualitas == null) _periksa();
  }

  Future<void> _periksa() async {
    try {
      final bytes = await File(widget.pathFoto).readAsBytes();
      final kualitas = PhotoQualityChecker.periksaBytes(bytes);
      if (mounted) setState(() => _kualitas = kualitas);
    } on Object catch (e) {
      if (mounted) setState(() => _galat = e.toString());
    }
  }

  Future<void> _gunakan() async {
    final kualitas = _kualitas;
    if (kualitas == null) return;
    await widget.onKonfirmasi?.call();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(kualitas);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kualitas = _kualitas;
    return Scaffold(
      appBar: AppBar(title: const Text('Periksa foto')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.horizontal,
          AppSpacing.sm,
          AppSpacing.horizontal,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.refresh),
                label: const Text('Foto ulang'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton.icon(
                onPressed: kualitas == null ? null : _gunakan,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Gunakan foto'),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.horizontal,
            AppSpacing.sm,
            AppSpacing.horizontal,
            AppSpacing.xl,
          ),
          children: [
            if (kualitas != null && !kualitas.layak) ...[
              KartuPesan(
                judul: kualitas.peringatan.first,
                isi: kualitas.peringatan.length > 1
                    ? kualitas.peringatan.skip(1).join('. ')
                    : kualitas.terlaluGelap
                    ? 'Cari cahaya merata dan hindari bayangan pada daun.'
                    : 'Pegang kamera stabil lalu fokuskan kembali pada gejala.',
                warna: context.palet.warning,
                ikon: Icons.warning_amber_rounded,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Align(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Semantics(
                  label: 'Pratinjau foto daun padi',
                  image: true,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sedang),
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 4 / 3,
                          child:
                              widget.pratinjau ??
                              Image.file(
                                File(widget.pathFoto),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 48,
                                  ),
                                ),
                              ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.kecil,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.55),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Pastikan daun terlihat jelas dan tidak buram.',
              style: context.teks.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Usahakan satu helai daun yang bergejala menjadi objek utama '
              'dengan pencahayaan cukup.',
              style: context.teks.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            if (kualitas == null && _galat == null)
              const Center(child: CircularProgressIndicator()),
            if (_galat != null)
              KartuPesan(
                judul: 'Foto tidak dapat diperiksa',
                isi: 'Pilih foto lain. $_galat',
                warna: context.palet.destructive,
                ikon: Icons.error_outline,
              ),
            if (kualitas != null && kualitas.layak)
              KartuPesan(
                judul: 'Foto siap dianalisis',
                isi:
                    'Pemeriksaan awal tidak menemukan masalah cahaya atau fokus.',
                warna: context.palet.success,
                ikon: Icons.check_circle_outline,
              ),
          ],
        ),
      ),
    );
  }
}
