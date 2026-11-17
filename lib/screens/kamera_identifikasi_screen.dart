import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/database_helper.dart';
import '../logic/photo_quality_checker.dart';
import '../logic/tflite_classifier.dart';
import '../models/hasil_identifikasi.dart';
import '../theme/app_tokens.dart';
import '../widgets/komponen.dart';
import 'hasil_screen.dart';
import 'panduan_foto_screen.dart';
import 'photo_preview_screen.dart';

/// Layar Kamera Identifikasi & Pengambilan Foto Daun (PRD F-03, F-04, S-04, S-06).
///
/// Menyediakan:
/// - Header: "Ambil Foto Daun"
/// - Area panduan framing daun dengan 5 aturan F-03
/// - Panduan bawah: "Pastikan daun terlihat jelas dan tidak buram."
/// - Tiga aksi bawah sesuai S-04: Galeri, Tombol Shutter (Ambil Foto), dan Panduan
/// - Penanganan galat izin kamera / kamera tidak tersedia sesuai tabel F-03
/// - Lapisan Analisis S-06 ("Menganalisis foto daun...", "Proses dilakukan langsung pada perangkat.")
class KameraIdentifikasiScreen extends StatefulWidget {
  const KameraIdentifikasiScreen({
    super.key,
    this.idPetakAwal,
    this.idMusimAwal,
    this.namaPetakAwal,
  });

  final int? idPetakAwal;
  final int? idMusimAwal;
  final String? namaPetakAwal;

  @override
  State<KameraIdentifikasiScreen> createState() =>
      _KameraIdentifikasiScreenState();
}

class _KameraIdentifikasiScreenState extends State<KameraIdentifikasiScreen> {
  final ImagePicker _picker = ImagePicker();
  final TfliteClassifier _classifier = TfliteClassifier();

  bool _memproses = false;
  String? _pathFotoMemproses;
  String? _judulGalat;
  String? _isiGalat;
  bool _tampilkanTipsLengkap = true;

  static const _limaPanduanF03 = <String>[
    'Fokuskan satu helai daun pada area tengah.',
    'Hindari foto terlalu gelap atau bayangan tajam.',
    'Hindari latar belakang yang terlalu ramai.',
    'Pastikan bagian daun yang bergejala terlihat jelas.',
    'Hindari foto yang buram.',
  ];

  @override
  void initState() {
    super.initState();
    _classifier.muat();
  }

  @override
  void dispose() {
    _classifier.tutup();
    super.dispose();
  }

  Future<void> _ambilDariSumber(ImageSource sumber) async {
    if (_memproses) return;
    setState(() {
      _judulGalat = null;
      _isiGalat = null;
    });

    try {
      final XFile? foto = await _picker.pickImage(
        source: sumber,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: sumber == ImageSource.camera ? 92 : null,
      );
      if (foto == null || !mounted) return;

      final berkas = File(foto.path);
      if (!await berkas.exists() || await berkas.length() == 0) {
        if (!mounted) return;
        setState(() {
          _judulGalat = 'File gambar rusak';
          _isiGalat =
              'Berkas foto tidak dapat dibaca. Silakan ambil ulang atau pilih foto lain.';
        });
        return;
      }

      if (!mounted) return;
      final kualitas = await Navigator.of(context).push<KualitasFoto>(
        MaterialPageRoute(
          builder: (_) => PhotoPreviewScreen(pathFoto: foto.path),
        ),
      );
      if (kualitas == null || !mounted) return;

      setState(() {
        _memproses = true;
        _pathFotoMemproses = foto.path;
      });

      final pathTersimpan = await DatabaseHelper.instance.salinFotoKeAplikasi(
        foto.path,
      );
      final mentah = await _classifier.identifikasi(pathTersimpan);
      final idRiwayat = await DatabaseHelper.instance.simpanRiwayat(
        Riwayat(
          pathFoto: mentah.pathFoto,
          idPenyakit: mentah.tidakDikenali ? '' : mentah.idPenyakit,
          keyakinan: mentah.keyakinan,
          waktu: mentah.waktu,
          idPetak: widget.idPetakAwal,
          idMusim: widget.idMusimAwal,
          status: mentah.tidakDikenali
              ? StatusIdentifikasi.tidakPasti
              : mentah.idPenyakit == 'normal'
              ? StatusIdentifikasi.sehat
              : StatusIdentifikasi.terklasifikasi,
          aturan: mentah.aturan,
          waktuPraprosesMs: mentah.waktuPraprosesMs,
          waktuInferensiMs: mentah.waktuInferensiMs,
          waktuTotalMs: mentah.waktuTotalMs,
          fotoGelap: kualitas.terlaluGelap,
          fotoBuram: kualitas.buram,
          modelVersion: TfliteClassifier.versiModel,
          probabilitasJson: jsonEncode({
            for (final item in mentah.semuaProbabilitas)
              item.idPenyakit: item.nilai,
          }),
        ),
      );

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
        idRiwayat: idRiwayat,
        idPetak: widget.idPetakAwal,
      );

      if (!mounted) return;
      setState(() {
        _memproses = false;
        _pathFotoMemproses = null;
      });

      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => HasilScreen(hasil: hasil)));
    } on PlatformException catch (e) {
      if (!mounted) return;
      final kode = e.code.toLowerCase();
      final izinDitolak =
          kode.contains('denied') || kode.contains('permission');
      final kameraTidakAda =
          kode.contains('camera') && kode.contains('available');
      setState(() {
        _memproses = false;
        _pathFotoMemproses = null;
        if (izinDitolak) {
          _judulGalat = 'Izin kamera atau penyimpanan ditolak';
          _isiGalat =
              'Berikan izin kamera di pengaturan perangkat untuk mengambil '
              'foto daun secara langsung, atau pilih foto daun dari Galeri.';
        } else if (kameraTidakAda) {
          _judulGalat = 'Kamera tidak tersedia';
          _isiGalat =
              'Perangkat tidak menyediakan akses kamera saat ini. Silakan '
              'gunakan tombol Galeri untuk memilih foto daun padi.';
        } else {
          _judulGalat = 'Pengambilan foto gagal';
          _isiGalat =
              'Gagal mengambil gambar (${e.message ?? e.code}). Silakan coba lagi.';
        }
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _memproses = false;
        _pathFotoMemproses = null;
        _judulGalat = 'Pemeriksaan gagal diproses';
        _isiGalat =
            'Pastikan format gambar JPG/PNG/WEBP valid lalu coba kembali. ($e)';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambil Foto Daun'),
        actions: [
          IconButton(
            tooltip: 'Panduan lengkap pengambilan foto',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PanduanFotoScreen()),
            ),
            icon: const Icon(Icons.help_outline_rounded),
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
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.smPlus,
          ),
          decoration: BoxDecoration(
            color: context.palet.card,
            borderRadius: BorderRadius.circular(AppRadius.sedang),
            border: Border.all(color: context.palet.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _memproses
                      ? null
                      : () => _ambilDariSumber(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galeri'),
                ),
              ),
              const SizedBox(width: AppSpacing.smPlus),
              Semantics(
                button: true,
                enabled: !_memproses,
                label: 'Tombol shutter ambil foto daun dengan kamera',
                child: FilledButton.icon(
                  onPressed: _memproses
                      ? null
                      : () => _ambilDariSumber(ImageSource.camera),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(148, 54),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                  ),
                  icon: const Icon(Icons.photo_camera_rounded),
                  label: const Text('Ambil Foto'),
                ),
              ),
              const SizedBox(width: AppSpacing.smPlus),
              IconButton.outlined(
                tooltip: 'Tampilkan / sembunyikan panduan framing',
                onPressed: () => setState(
                  () => _tampilkanTipsLengkap = !_tampilkanTipsLengkap,
                ),
                icon: Icon(
                  _tampilkanTipsLengkap
                      ? Icons.visibility_outlined
                      : Icons.lightbulb_outline,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.horizontal,
              AppSpacing.sm,
              AppSpacing.horizontal,
              AppSpacing.xl,
            ),
            children: [
              if (widget.namaPetakAwal != null &&
                  widget.namaPetakAwal!.isNotEmpty) ...[
                Lencana(
                  teks: 'Terkait lahan: ${widget.namaPetakAwal}',
                  warna: context.palet.primary,
                  ikon: Icons.grass_outlined,
                ),
                const SizedBox(height: AppSpacing.smPlus),
              ],
              if (_judulGalat != null && _isiGalat != null) ...[
                KartuPesan(
                  warna: context.palet.destructive,
                  ikon: Icons.error_outline,
                  judul: _judulGalat!,
                  isi: _isiGalat!,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _ambilDariSumber(ImageSource.camera),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Kamera Lagi'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => _ambilDariSumber(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Pilih dari Galeri'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Area kamera / panduan framing (PRD S-04)
              Card(
                color: context.palet.primaryDark,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(
                              AppRadius.kecil,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.65),
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.center_focus_strong_outlined,
                                size: 52,
                                color: context.palet.accent,
                              ),
                              const SizedBox(height: AppSpacing.smPlus),
                              Text(
                                'Area Fokus Satu Helai Daun Padi',
                                textAlign: TextAlign.center,
                                style: context.teks.titleMedium?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Posisikan bagian daun yang bergejala di tengah '
                                'bingkai dengan jarak 15–25 cm.',
                                textAlign: TextAlign.center,
                                style: context.teks.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.88),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Icon(
                            Icons.wb_sunny_outlined,
                            size: 18,
                            color: context.palet.accent,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Pastikan daun terlihat jelas dan tidak buram.',
                              style: context.teks.titleSmall?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (_tampilkanTipsLengkap) ...[
                const SizedBox(height: AppSpacing.md),
                KartuBagian(
                  judul: 'Panduan Pengambilan Foto (F-03)',
                  ikon: Icons.check_circle_outline,
                  anak: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < _limaPanduanF03.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.xs + 2,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${i + 1}. ',
                                style: context.teks.labelMedium?.copyWith(
                                  color: context.palet.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _limaPanduanF03[i],
                                  style: context.teks.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (_memproses)
            _LapisanAnalisisS06(pathFoto: _pathFotoMemproses),
        ],
      ),
    );
  }
}

/// Layar S-06 Analisis / Loading sesuai PRD Bagian 10:
/// - Foto kecil
/// - Indikator proses sederhana
/// - Teks: "Menganalisis foto daun..."
/// - Subteks: "Proses dilakukan langsung pada perangkat."
class _LapisanAnalisisS06 extends StatelessWidget {
  const _LapisanAnalisisS06({this.pathFoto});

  final String? pathFoto;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.palet.background.withValues(alpha: 0.92),
      child: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pathFoto != null && pathFoto!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.kecil),
                    child: SizedBox(
                      width: 88,
                      height: 88,
                      child: ImageFile(path: pathFoto!),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Menganalisis foto daun...',
                  textAlign: TextAlign.center,
                  style: context.teks.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Proses dilakukan langsung pada perangkat.',
                  textAlign: TextAlign.center,
                  style: context.teks.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
