import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/database_helper.dart';
import '../logic/tflite_classifier.dart';
import '../logic/photo_quality_checker.dart';
import '../models/hasil_identifikasi.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/komponen.dart';
import 'hasil_screen.dart';
import 'informasi_screen.dart';
import 'panduan_foto_screen.dart';
import 'photo_preview_screen.dart';
import 'petak_screen.dart';
import 'pengaturan_screen.dart';
import 'riwayat_screen.dart';
import 'statistik_screen.dart';

/// Halaman beranda.
///
/// Gaya mengikuti pola sekali-pakai, bukan halaman pendaratan: satu tindakan
/// utama (memotret daun) langsung tersedia tanpa perlu menggulir. Lihat
/// `design-system/padi-scan/OVERRIDES.md` butir 4.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final TfliteClassifier _classifier = TfliteClassifier();

  bool _memproses = false;
  bool _modelSiap = false;
  String? _pesanError;
  int _jumlahRiwayat = 0;

  @override
  void initState() {
    super.initState();
    _muatModel();
    _hitungRiwayat();
  }

  @override
  void dispose() {
    _classifier.tutup();
    super.dispose();
  }

  Future<void> _muatModel() async {
    final siap = await _classifier.muat();
    if (!mounted) return;
    setState(() => _modelSiap = siap);
  }

  /// Jumlah riwayat dipakai untuk lencana pintasan. Kegagalan basis data
  /// tidak boleh merusak beranda, jadi galat ditelan dan nilai tetap 0.
  Future<void> _hitungRiwayat() async {
    try {
      final data = await DatabaseHelper.instance.semuaRiwayat();
      if (!mounted) return;
      setState(() => _jumlahRiwayat = data.length);
    } on Object catch (e) {
      debugPrint('[Home] gagal menghitung riwayat: $e');
    }
  }

  Future<void> _ambilFoto(ImageSource sumber) async {
    if (_memproses) return;
    setState(() => _pesanError = null);

    try {
      final XFile? foto = await _picker.pickImage(
        source: sumber,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 92,
      );
      if (foto == null) return;

      if (!mounted) return;
      final kualitas = await Navigator.of(context).push<KualitasFoto>(
        MaterialPageRoute(
          builder: (_) => PhotoPreviewScreen(pathFoto: foto.path),
        ),
      );
      if (kualitas == null || !mounted) return;

      setState(() => _memproses = true);

      final path = await DatabaseHelper.instance.salinFotoKeAplikasi(foto.path);
      final mentah = await _classifier.identifikasi(path);
      final hasil = HasilIdentifikasi(
        idPenyakit: mentah.idPenyakit,
        keyakinan: mentah.keyakinan,
        semuaProbabilitas: mentah.semuaProbabilitas,
        tidakDikenali: mentah.tidakDikenali,
        waktuInferensiMs: mentah.waktuInferensiMs,
        waktuPraprosesMs: mentah.waktuPraprosesMs,
        waktuTotalMs: mentah.waktuTotalMs,
        aturan: mentah.aturan,
        peringatanKualitas: kualitas.peringatan,
        pathFoto: mentah.pathFoto,
        waktu: mentah.waktu,
      );

      await DatabaseHelper.instance.simpanRiwayat(
        Riwayat(
          pathFoto: hasil.pathFoto,
          idPenyakit: hasil.tidakDikenali ? '' : hasil.idPenyakit,
          keyakinan: hasil.keyakinan,
          waktu: hasil.waktu,
          status: hasil.tidakDikenali
              ? StatusIdentifikasi.tidakPasti
              : hasil.idPenyakit == 'normal'
              ? StatusIdentifikasi.sehat
              : StatusIdentifikasi.terklasifikasi,
          aturan: hasil.aturan,
          waktuPraprosesMs: hasil.waktuPraprosesMs,
          waktuInferensiMs: hasil.waktuInferensiMs,
          waktuTotalMs: hasil.waktuTotalMs,
          fotoGelap: kualitas.terlaluGelap,
          fotoBuram: kualitas.buram,
          modelVersion: TfliteClassifier.versiModel,
          probabilitasJson: jsonEncode({
            for (final item in hasil.semuaProbabilitas)
              item.idPenyakit: item.nilai,
          }),
        ),
      );

      if (!mounted) return;
      setState(() => _memproses = false);
      await _hitungRiwayat();

      if (!mounted) return;
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => HasilScreen(hasil: hasil)));
      if (mounted) await _hitungRiwayat();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _memproses = false;
        _pesanError = e.toString();
      });
    }
  }

  Future<void> _buka(Widget layar) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => layar));
    if (mounted) await _hitungRiwayat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                await _muatModel();
                await _hitungRiwayat();
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _BilahAtas(modelSiap: _modelSiap)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.xl,
                    ),
                    sliver: SliverList.list(
                      children: [
                        _TindakanUtama(
                          aktif: !_memproses,
                          onKamera: () => _ambilFoto(ImageSource.camera),
                          onGaleri: () => _ambilFoto(ImageSource.gallery),
                          onPanduan: () => _buka(const PanduanFotoScreen()),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (!_modelSiap) const _PeringatanModel(),
                        if (_pesanError != null)
                          KartuPesan(
                            warna: context.palet.destructive,
                            ikon: Icons.error_outline,
                            judul: 'Identifikasi gagal',
                            isi: _pesanError!,
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                          ),
                        OutlinedButton.icon(
                          onPressed: () => _buka(const PetakScreen()),
                          icon: const Icon(Icons.grid_view_outlined),
                          label: const Text('Buka Catatan Lapangan'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const SizedBox(height: AppSpacing.sm),
                        _MenuCepat(
                          jumlahRiwayat: _jumlahRiwayat,
                          onRiwayat: () => _buka(const RiwayatScreen()),
                          onInformasi: () => _buka(const InformasiScreen()),
                          onStatistik: () => _buka(const StatistikScreen()),
                          onPengaturan: () => _buka(const PengaturanScreen()),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const _CaraPakai(),
                        const SizedBox(height: AppSpacing.md),
                        const _CatatanOffline(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_memproses) const _LapisanMemproses(),
          ],
        ),
      ),
    );
  }
}

/// Bilah atas: nama aplikasi dan lencana kesiapan model.
class _BilahAtas extends StatelessWidget {
  const _BilahAtas({required this.modelSiap});

  final bool modelSiap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.palet.primary,
                borderRadius: BorderRadius.circular(AppRadius.kecil),
              ),
              child: Icon(
                Icons.eco_rounded,
                color: context.palet.onPrimary,
                size: AppIkon.besar,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Padi Scan', style: context.teks.titleLarge),
                Text(
                  'Identifikasi Penyakit Daun Padi',
                  style: context.teks.bodySmall,
                ),
              ],
            ),
          ),
          if (modelSiap)
            Lencana(
              teks: 'Siap',
              warna: context.palet.success,
              ikon: Icons.check_circle_outline,
            )
          else
            Lencana(
              teks: 'Model kosong',
              warna: context.palet.warning,
              ikon: Icons.warning_amber_rounded,
            ),
        ],
      ),
    );
  }
}

/// Kartu tindakan utama (F-01 dan F-02).
class _TindakanUtama extends StatelessWidget {
  const _TindakanUtama({
    required this.aktif,
    required this.onKamera,
    required this.onGaleri,
    required this.onPanduan,
  });

  final bool aktif;
  final VoidCallback onKamera;
  final VoidCallback onGaleri;
  final VoidCallback onPanduan;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg - 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Periksa daun padi Anda', style: context.teks.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Arahkan kamera ke bagian daun yang bergejala. '
              'Hasil muncul dalam hitungan detik dan dapat dibuka '
              'tanpa koneksi internet.',
              style: context.teks.bodyMedium?.copyWith(
                color: context.palet.mutedForeground,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              button: true,
              enabled: aktif,
              label: 'Ambil foto daun dengan kamera',
              child: FilledButton.icon(
                onPressed: aktif ? onKamera : null,
                icon: const Icon(Icons.photo_camera_rounded),
                label: const Text('Ambil Foto Daun'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            Semantics(
              button: true,
              enabled: aktif,
              label: 'Pilih foto daun dari galeri',
              child: OutlinedButton.icon(
                onPressed: aktif ? onGaleri : null,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Pilih dari Galeri'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              button: true,
              label: 'Buka panduan pengambilan foto',
              child: TextButton.icon(
                onPressed: onPanduan,
                icon: const Icon(Icons.help_outline_rounded),
                label: const Text('Panduan Ambil Foto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empat pintu cepat ke F-07, F-08, statistik, dan pengaturan.
class _MenuCepat extends StatelessWidget {
  const _MenuCepat({
    required this.jumlahRiwayat,
    required this.onRiwayat,
    required this.onInformasi,
    required this.onStatistik,
    required this.onPengaturan,
  });

  final int jumlahRiwayat;
  final VoidCallback onRiwayat;
  final VoidCallback onInformasi;
  final VoidCallback onStatistik;
  final VoidCallback onPengaturan;

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight wajib membungkus tiap Row, bukan Column: Column
    // meneruskan maxHeight tak terbatas ke anak non-flex, sehingga
    // `CrossAxisAlignment.stretch` pada Row memaksa tinggi anak menjadi
    // tak hingga dan tata letak gagal.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _KotakMenu(
                  ikon: Icons.history_rounded,
                  judul: 'Riwayat',
                  keterangan: jumlahRiwayat == 0
                      ? 'Belum ada hasil'
                      : '$jumlahRiwayat hasil tersimpan',
                  onTap: onRiwayat,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: _KotakMenu(
                  ikon: Icons.menu_book_outlined,
                  judul: 'Info Penyakit',
                  keterangan: 'Empat kelas',
                  onTap: onInformasi,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm + 4),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _KotakMenu(
                  ikon: Icons.insights_rounded,
                  judul: 'Statistik',
                  keterangan: 'Ringkasan hasil',
                  onTap: onStatistik,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: _KotakMenu(
                  ikon: Icons.tune_rounded,
                  judul: 'Pengaturan',
                  keterangan: 'Tema dan data',
                  onTap: onPengaturan,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KotakMenu extends StatelessWidget {
  const _KotakMenu({
    required this.ikon,
    required this.judul,
    required this.keterangan,
    required this.onTap,
  });

  final IconData ikon;
  final String judul;
  final String keterangan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$judul, $keterangan',
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.palet.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.kecil - 2),
                    ),
                    child: Icon(
                      ikon,
                      color: context.palet.primary,
                      size: AppIkon.sedang,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                Text(judul, style: context.teks.titleSmall),
                const SizedBox(height: 2),
                Text(
                  keterangan,
                  style: context.teks.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Petunjuk singkat tiga langkah.
class _CaraPakai extends StatelessWidget {
  const _CaraPakai();

  static const _langkah = <(String, String, String)>[
    ('1', 'Ambil foto', 'Dekatkan kamera pada daun yang bergejala.'),
    ('2', 'Tunggu hasil', 'Aplikasi membaca citra langsung di perangkat.'),
    ('3', 'Ikuti saran', 'Baca rekomendasi penanganan beserta sumbernya.'),
  ];

  @override
  Widget build(BuildContext context) {
    return KartuBagian(
      judul: 'Cara pakai',
      ikon: Icons.help_outline_rounded,
      anak: Column(
        children: [
          for (var i = 0; i < _langkah.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm + 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.palet.muted,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.palet.border),
                    ),
                    child: Text(
                      _langkah[i].$1,
                      style: TextStyle(
                        fontFamily: AppTheme.keluargaFont,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: context.palet.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_langkah[i].$2, style: context.teks.titleSmall),
                      const SizedBox(height: 2),
                      Text(_langkah[i].$3, style: context.teks.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PeringatanModel extends StatelessWidget {
  const _PeringatanModel();

  @override
  Widget build(BuildContext context) {
    return KartuPesan(
      warna: context.palet.warning,
      ikon: Icons.warning_amber_rounded,
      judul: 'Model identifikasi belum tersedia',
      isi:
          'Letakkan berkas "${TfliteClassifier.pathModel}" pada folder '
          'assets aplikasi, lalu bangun ulang aplikasi. Selama berkas itu '
          'belum ada, tombol identifikasi tidak dapat dipakai.',
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
    );
  }
}

class _CatatanOffline extends StatelessWidget {
  const _CatatanOffline();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Icon(
            Icons.wifi_off_rounded,
            size: AppIkon.kecil,
            color: context.palet.mutedForeground,
          ),
        ),
        const SizedBox(width: AppSpacing.sm + 2),
        Expanded(
          child: Text(
            'Seluruh proses identifikasi berjalan di dalam perangkat, tanpa '
            'mengirim citra ke server mana pun.',
            style: context.teks.bodySmall,
          ),
        ),
      ],
    );
  }
}

/// Lapisan proses. Diberi penghalang sentuh dan pengumuman pembaca layar.
class _LapisanMemproses extends StatelessWidget {
  const _LapisanMemproses();

  @override
  Widget build(BuildContext context) {
    final kurangiGerak = MediaQuery.disableAnimationsOf(context);

    return Positioned.fill(
      child: Semantics(
        liveRegion: true,
        label: 'Sedang mengidentifikasi daun',
        child: AbsorbPointer(
          child: ColoredBox(
            color: context.palet.foreground.withValues(alpha: 0.55),
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 42,
                        height: 42,
                        child: kurangiGerak
                            ? Icon(
                                Icons.hourglass_top_rounded,
                                color: context.palet.primary,
                                size: 32,
                              )
                            : CircularProgressIndicator(
                                strokeWidth: 4,
                                color: context.palet.primary,
                              ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Mengidentifikasi daun...',
                        style: context.teks.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Mohon tunggu sebentar.',
                        style: context.teks.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
