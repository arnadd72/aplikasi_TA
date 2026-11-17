import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../data/pengaturan.dart';
import '../logic/tflite_classifier.dart';
import '../theme/app_tokens.dart';
import '../widgets/komponen.dart';
import 'app_shell.dart';
import 'onboarding_screen.dart';

/// Layar pembuka aplikasi (PRD S-01 Splash Screen).
///
/// Memeriksa ketersediaan model TFLite, basis data SQLite, dan pengaturan
/// lokal. Jika gagal, menampilkan pesan yang jelas dan tidak berputar
/// tanpa batas.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.lewatiPemeriksaanModel = false});

  final bool lewatiPemeriksaanModel;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _memeriksa = true;
  String? _galatModel;

  @override
  void initState() {
    super.initState();
    _inisialisasi();
  }

  Future<void> _inisialisasi() async {
    setState(() {
      _memeriksa = true;
      _galatModel = null;
    });

    await PengaturanStore.instance.muat();

    try {
      await DatabaseHelper.instance.semuaPenyakit();
    } on Object catch (e) {
      debugPrint('[Splash] basis data belum siap: $e');
    }

    if (!widget.lewatiPemeriksaanModel) {
      final classifier = TfliteClassifier();
      final siap = await classifier.muat();
      classifier.tutup();
      if (!siap && mounted) {
        setState(() {
          _memeriksa = false;
          _galatModel =
              'Model MobileNetV2 (TensorFlow Lite) tidak dapat dimuat pada '
              'perangkat ini. Pastikan berkas model tersedia di aset aplikasi.';
        });
        return;
      }
    }

    if (!mounted) return;
    _lanjutKeTujuan();
  }

  void _lanjutKeTujuan() {
    final selesaiOnboarding = PengaturanStore.instance.onboardingSelesai.value;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            selesaiOnboarding ? const AppShell() : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palet.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.horizontal,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.palet.primary,
                      borderRadius: BorderRadius.circular(AppRadius.sedang),
                    ),
                    child: Icon(
                      Icons.eco_outlined,
                      size: 36,
                      color: context.palet.onPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Padi Scan', style: context.teks.headlineMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Identifikasi Penyakit Daun Padi',
                    textAlign: TextAlign.center,
                    style: context.teks.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (_memeriksa) ...[
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Menyiapkan model dan basis data lokal…',
                      style: context.teks.labelMedium,
                    ),
                  ] else if (_galatModel != null) ...[
                    KartuPesan(
                      warna: context.palet.destructive,
                      ikon: Icons.error_outline,
                      judul: 'Model belum siap',
                      isi: _galatModel!,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: _inisialisasi,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: _lanjutKeTujuan,
                      child: const Text('Tetap Buka Aplikasi'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
