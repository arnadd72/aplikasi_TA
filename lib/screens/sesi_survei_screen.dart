import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/catatan_lapangan_repository.dart';
import '../data/database_helper.dart';
import '../logic/photo_quality_checker.dart';
import '../logic/tflite_classifier.dart';
import '../models/catatan_lapangan.dart';
import '../models/hasil_identifikasi.dart';
import '../theme/app_tokens.dart';
import '../widgets/komponen.dart';
import 'hasil_screen.dart';
import 'photo_preview_screen.dart';

class SesiSurveiScreen extends StatefulWidget {
  const SesiSurveiScreen({
    super.key,
    required this.sesi,
    required this.namaPetak,
    this.repository,
    this.onPeriksa,
    this.onSelesai,
    this.pengamatanAwal = const [],
  });

  final SesiSurvei sesi;
  final String namaPetak;
  final CatatanLapanganRepository? repository;
  final Future<PengamatanSurvei?> Function()? onPeriksa;
  final Future<void> Function()? onSelesai;
  final List<PengamatanSurvei> pengamatanAwal;

  @override
  State<SesiSurveiScreen> createState() => _SesiSurveiScreenState();
}

class _SesiSurveiScreenState extends State<SesiSurveiScreen> {
  final _pengamatan = <PengamatanSurvei>[];
  final _picker = ImagePicker();
  final _classifier = TfliteClassifier();
  bool _sibuk = false;
  int _jumlahGagal = 0;

  @override
  void initState() {
    super.initState();
    _pengamatan.addAll(widget.pengamatanAwal);
  }

  @override
  void dispose() {
    _classifier.tutup();
    super.dispose();
  }

  Future<ImageSource?> _pilihSumber() => showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            minVerticalPadding: AppSpacing.sm,
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Ambil dengan kamera'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            minVerticalPadding: AppSpacing.sm,
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Pilih dari galeri'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );

  Future<PengamatanSurvei?> _periksaDiPerangkat() async {
    final sumber = await _pilihSumber();
    if (sumber == null) return null;
    final foto = await _picker.pickImage(
      source: sumber,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: sumber == ImageSource.camera ? 92 : null,
    );
    if (foto == null || !mounted) return null;
    final kualitas = await Navigator.of(context).push<KualitasFoto>(
      MaterialPageRoute(
        builder: (_) => PhotoPreviewScreen(pathFoto: foto.path),
      ),
    );
    if (kualitas == null) return null;

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
        pathFoto: path,
        idPenyakit: hasil.tidakDikenali ? '' : hasil.idPenyakit,
        keyakinan: hasil.keyakinan,
        waktu: hasil.waktu,
        idPetak: widget.sesi.idPetak,
        idMusim: widget.sesi.idMusim,
        idSesi: widget.sesi.idSesi,
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
    if (mounted) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => HasilScreen(hasil: hasil)));
    }
    return PengamatanSurvei(
      idPenyakit: hasil.idPenyakit,
      tidakPasti: hasil.tidakDikenali,
    );
  }

  Future<void> _periksa() async {
    if (_sibuk) return;
    setState(() => _sibuk = true);
    try {
      final item = await (widget.onPeriksa?.call() ?? _periksaDiPerangkat());
      if (item != null && mounted) setState(() => _pengamatan.add(item));
    } on Object catch (e) {
      if (mounted) {
        setState(() => _jumlahGagal++);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Pemeriksaan gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  Future<void> _selesai() async {
    await widget.onSelesai?.call();
    if (widget.onSelesai == null && widget.sesi.idSesi != null) {
      await widget.repository?.selesaikanSesi(
        widget.sesi.idSesi!,
        DateTime.now(),
      );
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  String _namaKelas(String id) => switch (id) {
    'blas' => 'Blas',
    'hawar_daun_bakteri' => 'Hawar daun bakteri',
    'bercak_cokelat' => 'Bercak cokelat',
    'normal' => 'Sehat',
    _ => id,
  };

  @override
  Widget build(BuildContext context) {
    final ringkasan = RingkasanSesi.dariPengamatan(_pengamatan);
    final tercapai = ringkasan.totalDaun >= widget.sesi.targetDaun;
    return Scaffold(
      appBar: AppBar(title: const Text('Survei daun')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(widget.namaPetak, style: context.teks.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${ringkasan.totalDaun} dari ${widget.sesi.targetDaun} daun',
            style: context.teks.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: widget.sesi.targetDaun == 0
                ? 0
                : (ringkasan.totalDaun / widget.sesi.targetDaun).clamp(
                    0.0,
                    1.0,
                  ),
            minHeight: 10,
          ),
          const SizedBox(height: AppSpacing.lg),
          KartuBagian(
            judul: 'Ringkasan sementara',
            ikon: Icons.fact_check_outlined,
            anak: ringkasan.totalDaun == 0 && _jumlahGagal == 0
                ? const Text('Belum ada daun yang diperiksa.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final item in ringkasan.jumlahPerKelas.entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Text('${_namaKelas(item.key)}: ${item.value}'),
                        ),
                      if (ringkasan.jumlahTidakPasti > 0)
                        Text('Tidak pasti: ${ringkasan.jumlahTidakPasti}'),
                      if (_jumlahGagal > 0) Text('Gagal: $_jumlahGagal'),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _sibuk || tercapai ? null : _periksa,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(_sibuk ? 'Memproses…' : 'Periksa daun berikutnya'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: ringkasan.totalDaun == 0 ? null : _selesai,
            icon: const Icon(Icons.check),
            label: Text(tercapai ? 'Selesaikan survei' : 'Selesai lebih awal'),
          ),
        ],
      ),
    );
  }
}
