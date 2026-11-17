import 'package:flutter/material.dart';

import '../data/pengaturan.dart';
import '../theme/app_tokens.dart';
import 'app_shell.dart';

/// Layar pengenalan aplikasi maksimal 3 halaman (PRD F-01 & S-02).
///
/// Menampilkan fotografi daun padi asli dari dataset penelitian, penjelasan
/// empat kelas cakupan model, dan informasi kerja luring tanpa login.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.onSelesai});

  final VoidCallback? onSelesai;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _HalamanOnboarding {
  final String judul;
  final String deskripsi;
  final String keteranganTambahan;
  final String pathGambar;
  final List<String> butir;

  const _HalamanOnboarding({
    required this.judul,
    required this.deskripsi,
    required this.keteranganTambahan,
    required this.pathGambar,
    this.butir = const [],
  });
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _indeks = 0;

  static const List<_HalamanOnboarding> _halaman = [
    _HalamanOnboarding(
      judul: 'Kenali penyakit daun padi',
      deskripsi: 'Ambil foto daun padi untuk mengetahui kemungkinan penyakitnya.',
      keteranganTambahan:
          'Model MobileNetV2 mengenali empat kelas kondisi daun padi:',
      pathGambar: 'assets/images/blas.jpg',
      butir: [
        'C01 · Blas (Blas Daun)',
        'C02 · Hawar Daun Bakteri (HDB)',
        'C03 · Bercak Cokelat',
        'C04 · Daun Sehat',
      ],
    ),
    _HalamanOnboarding(
      judul: 'Dapatkan panduan penanganan',
      deskripsi:
          'Lihat informasi penyakit dan langkah perawatan awal berdasarkan sumber pertanian.',
      keteranganTambahan:
          'Rekomendasi mengutamakan kultur teknis dan pencegahan, serta hanya '
          'mencantumkan bahan aktif tanpa merek dagang maupun dosis otomatis.',
      pathGambar: 'assets/images/hawar_daun_bakteri.jpg',
      butir: [
        'Alat bantu keputusan awal, bukan pengganti penyuluh (PPL/POPT)',
        'Dilengkapi pencatatan lahan, pengamatan, dan jadwal perawatan',
      ],
    ),
    _HalamanOnboarding(
      judul: 'Gunakan tanpa internet',
      deskripsi:
          'Identifikasi penyakit dan buka riwayat tersimpan langsung dari perangkat.',
      keteranganTambahan:
          'Tidak memerlukan login. Izin kamera hanya diminta ketika Anda '
          'mengambil foto daun, dan seluruh foto tersimpan lokal di perangkat Anda.',
      pathGambar: 'assets/images/normal.jpg',
      butir: [
        'Inferensi AI berjalan penuh di perangkat (offline-first)',
        'Data riwayat dan catatan lahan bertahan meski aplikasi ditutup',
      ],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selesaikan() async {
    await PengaturanStore.instance.simpanOnboardingSelesai(true);
    if (!mounted) return;
    if (widget.onSelesai != null) {
      widget.onSelesai!();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  void _berikutnya() {
    if (_indeks < _halaman.length - 1) {
      _controller.nextPage(
        duration: AppDurasi.sedang,
        curve: Curves.easeOutCubic,
      );
    } else {
      _selesaikan();
    }
  }

  @override
  Widget build(BuildContext context) {
    final terakhir = _indeks == _halaman.length - 1;

    return Scaffold(
      backgroundColor: context.palet.background,
      appBar: AppBar(
        backgroundColor: context.palet.background,
        title: Row(
          children: [
            Icon(
              Icons.eco_outlined,
              size: AppIkon.sedang,
              color: context.palet.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('Padi Scan', style: context.teks.titleLarge),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _selesaikan,
            child: const Text('Lewati'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.horizontal,
          AppSpacing.sm,
          AppSpacing.horizontal,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _halaman.length; i++)
                  AnimatedContainer(
                    duration: AppDurasi.cepat,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _indeks ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _indeks
                          ? context.palet.primary
                          : context.palet.border,
                      borderRadius: BorderRadius.circular(AppRadius.pil),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _berikutnya,
              child: Text(terakhir ? 'Mulai' : 'Lanjut'),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: PageView.builder(
          controller: _controller,
          itemCount: _halaman.length,
          onPageChanged: (nilai) => setState(() => _indeks = nilai),
          itemBuilder: (context, index) {
            final item = _halaman[index];
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.horizontal,
                AppSpacing.sm,
                AppSpacing.horizontal,
                AppSpacing.lg,
              ),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sedang),
                  child: SizedBox(
                    height: 170,
                    width: double.infinity,
                    child: Image.asset(
                      item.pathGambar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: context.palet.muted,
                        child: Center(
                          child: Icon(
                            Icons.eco_outlined,
                            size: 48,
                            color: context.palet.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(item.judul, style: context.teks.headlineMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(item.deskripsi, style: context.teks.bodyLarge),
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.keteranganTambahan,
                          style: context.teks.bodySmall?.copyWith(
                            color: context.palet.foreground,
                          ),
                        ),
                        if (item.butir.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.smPlus),
                          for (final b in item.butir)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.xs + 2,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Icon(
                                      Icons.check_circle_outline,
                                      size: 16,
                                      color: context.palet.primary,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      b,
                                      style: context.teks.bodySmall?.copyWith(
                                        color: context.palet.cardForeground,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
