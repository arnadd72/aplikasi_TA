import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/catatan_lapangan_repository.dart';
import '../data/database_helper.dart';
import '../logic/photo_quality_checker.dart';
import '../logic/tflite_classifier.dart';
import '../models/catatan_lapangan.dart';
import '../models/hasil_identifikasi.dart';
import '../models/penyakit.dart';
import '../theme/app_tokens.dart';
import '../utils/format_waktu.dart';
import '../widgets/komponen.dart';
import 'detail_riwayat_screen.dart';
import 'form_petak_screen.dart';
import 'hasil_screen.dart';
import 'photo_preview_screen.dart';

/// Halaman Detail Lahan, Catatan Pengamatan Manual, Jadwal Perawatan,
/// dan Monitoring Perkembangan / Perbandingan Foto (PRD F-12, F-13, F-16,
/// F-18, F-19, S-12, S-13, S-16, S-17).
class TimelinePetakScreen extends StatefulWidget {
  const TimelinePetakScreen({
    super.key,
    required this.petak,
    required this.repository,
  });

  final Petak petak;
  final CatatanLapanganRepository repository;

  @override
  State<TimelinePetakScreen> createState() => _TimelinePetakScreenState();
}

class _TimelinePetakScreenState extends State<TimelinePetakScreen> {
  late Petak _petak;
  int? _idMusim;
  StatusIdentifikasi? _status;
  bool _memprosesAi = false;

  final ImagePicker _picker = ImagePicker();
  final TfliteClassifier _classifier = TfliteClassifier();

  List<MusimTanam> _musim = const [];
  List<Riwayat> _riwayat = const [];
  List<CatatanPengamatan> _pengamatan = const [];
  List<JadwalPerawatan> _jadwal = const [];
  bool _memuat = true;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _petak = widget.petak;
    _muatSemua();
  }

  @override
  void dispose() {
    _classifier.tutup();
    super.dispose();
  }

  Future<void> _muatSemua() async {
    setState(() {
      _memuat = true;
      _galat = null;
    });
    try {
      final id = _petak.idPetak!;
      final semuaPetak = await widget.repository.semuaPetak();
      final terbaru = semuaPetak.where((p) => p.idPetak == id).firstOrNull;
      if (terbaru != null) _petak = terbaru;

      final musim = await widget.repository.musimUntukPetak(id);
      final riwayat = await widget.repository.timelinePetak(id);
      List<CatatanPengamatan> pengamatan = const [];
      List<JadwalPerawatan> jadwal = const [];
      try {
        pengamatan = await widget.repository.pengamatanUntukPetak(id);
        jadwal = await widget.repository.jadwalUntukPetak(id);
      } on Object catch (e) {
        debugPrint('[Timeline] pengamatan/jadwal dilewati: $e');
      }
      if (!mounted) return;
      setState(() {
        _musim = musim;
        _riwayat = riwayat;
        _pengamatan = pengamatan;
        _jadwal = jadwal;
        _memuat = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _galat = e.toString();
        _memuat = false;
      });
    }
  }

  Future<void> _editLahan() async {
    final berubah = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            FormPetakScreen(repository: widget.repository, petakAwal: _petak),
      ),
    );
    if (berubah == true && mounted) {
      await _muatSemua();
    }
  }

  /// Alur 11.2 PRD: Identifikasi Terkait Lahan langsung dari Detail Lahan.
  Future<void> _tambahPemeriksaanAi() async {
    if (_memprosesAi) return;
    final sumber = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Ambil Foto dengan Kamera'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (sumber == null || !mounted) return;

    try {
      final foto = await _picker.pickImage(
        source: sumber,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: sumber == ImageSource.camera ? 92 : null,
      );
      if (foto == null || !mounted) return;
      final kualitas = await Navigator.of(context).push<KualitasFoto>(
        MaterialPageRoute(
          builder: (_) => PhotoPreviewScreen(pathFoto: foto.path),
        ),
      );
      if (kualitas == null || !mounted) return;

      setState(() => _memprosesAi = true);
      final path = await DatabaseHelper.instance.salinFotoKeAplikasi(foto.path);
      final mentah = await _classifier.identifikasi(path);
      final musimAktif = _musim.where((m) => m.aktif).firstOrNull;

      final idRiwayat = await DatabaseHelper.instance.simpanRiwayat(
        Riwayat(
          pathFoto: mentah.pathFoto,
          idPenyakit: mentah.tidakDikenali ? '' : mentah.idPenyakit,
          keyakinan: mentah.keyakinan,
          waktu: mentah.waktu,
          idPetak: _petak.idPetak,
          idMusim: musimAktif?.idMusim,
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
        idPetak: _petak.idPetak,
      );

      if (!mounted) return;
      setState(() => _memprosesAi = false);
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => HasilScreen(hasil: hasil)));
      if (mounted) await _muatSemua();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _memprosesAi = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Pemeriksaan gagal: $e')));
    }
  }

  /// S-13 / F-13: Tambah atau Edit Catatan Pengamatan Manual.
  Future<void> _formPengamatan({CatatanPengamatan? awal}) async {
    final kondisiCtrl = TextEditingController(
      text: awal?.kondisiTanaman ?? 'Pertumbuhan normal, perlu pemantauan',
    );
    final gejalaCtrl = TextEditingController(text: awal?.gejalaDiamati ?? '');
    final tindakanCtrl = TextEditingController(
      text: awal?.tindakanDilakukan ?? '',
    );
    final catatanCtrl = TextEditingController(
      text: awal?.catatanTambahan ?? '',
    );
    DateTime tanggal = awal?.tanggal ?? DateTime.now();

    final simpan = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            awal == null ? 'Tambah Pengamatan' : 'Edit Pengamatan',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final pilih = await showDatePicker(
                      context: ctx,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDate: tanggal,
                    );
                    if (pilih != null) {
                      setDialogState(() => tanggal = pilih);
                    }
                  },
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text('Tanggal: ${FormatWaktu.panjang(tanggal)}'),
                ),
                const SizedBox(height: AppSpacing.smPlus),
                TextField(
                  controller: kondisiCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kondisi tanaman',
                    hintText: 'Contoh: Daun mulai menghijau / gejala berkurang',
                  ),
                ),
                const SizedBox(height: AppSpacing.smPlus),
                TextField(
                  controller: gejalaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Gejala yang diamati (opsional)',
                    hintText: 'Contoh: Bercak pada daun bawah 3 rumpun',
                  ),
                ),
                const SizedBox(height: AppSpacing.smPlus),
                TextField(
                  controller: tindakanCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tindakan yang dilakukan (opsional)',
                    hintText: 'Contoh: Pengairan berselang & sanitasi gulma',
                  ),
                ),
                const SizedBox(height: AppSpacing.smPlus),
                TextField(
                  controller: catatanCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Catatan tambahan (opsional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (simpan == true && kondisiCtrl.text.trim().isNotEmpty) {
      await widget.repository.simpanPengamatan(
        CatatanPengamatan(
          idPengamatan: awal?.idPengamatan,
          idPetak: _petak.idPetak!,
          tanggal: tanggal,
          kondisiTanaman: kondisiCtrl.text,
          gejalaDiamati: gejalaCtrl.text,
          tindakanDilakukan: tindakanCtrl.text,
          catatanTambahan: catatanCtrl.text,
          dibuatPada: awal?.dibuatPada ?? DateTime.now(),
        ),
      );
      if (mounted) await _muatSemua();
    }
    kondisiCtrl.dispose();
    gejalaCtrl.dispose();
    tindakanCtrl.dispose();
    catatanCtrl.dispose();
  }

  /// S-16 / F-16: Tambah Jadwal Perawatan Lahan.
  Future<void> _tambahJadwal() async {
    String jenis = JadwalPerawatan.jenisKegiatanAwal.first;
    final catatanCtrl = TextEditingController();
    DateTime tanggal = DateTime.now().add(const Duration(days: 3));

    final simpan = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tambah Jadwal Perawatan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: jenis,
                  decoration: const InputDecoration(labelText: 'Jenis kegiatan'),
                  items: [
                    for (final k in JadwalPerawatan.jenisKegiatanAwal)
                      DropdownMenuItem(value: k, child: Text(k)),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => jenis = v);
                  },
                ),
                const SizedBox(height: AppSpacing.smPlus),
                OutlinedButton.icon(
                  onPressed: () async {
                    final pilih = await showDatePicker(
                      context: ctx,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 30),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDate: tanggal,
                    );
                    if (pilih != null) {
                      setDialogState(() => tanggal = pilih);
                    }
                  },
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Text('Jadwal: ${FormatWaktu.panjang(tanggal)}'),
                ),
                const SizedBox(height: AppSpacing.smPlus),
                TextField(
                  controller: catatanCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Catatan kegiatan (opsional)',
                    hintText: 'Contoh: Periksa daun bendera blok timur',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Simpan Jadwal'),
            ),
          ],
        ),
      ),
    );

    if (simpan == true) {
      await widget.repository.simpanJadwal(
        JadwalPerawatan(
          idPetak: _petak.idPetak!,
          judul: jenis,
          catatan: catatanCtrl.text,
          tanggalJadwal: tanggal,
        ),
      );
      if (mounted) await _muatSemua();
    }
    catatanCtrl.dispose();
  }

  /// S-17 / F-19: Perbandingan Foto Sebelum vs Sesudah.
  Future<void> _bandingkanFoto() async {
    if (_riwayat.length < 2) return;
    Riwayat sebelum = _riwayat.last;
    Riwayat sesudah = _riwayat.first;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Perbandingan Foto Lahan'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Bandingkan kondisi visual daun antara dua waktu '
                    'pemeriksaan. Aplikasi tidak otomatis menyimpulkan '
                    'tanaman sembuh hanya dari perubahan foto.',
                    style: ctx.teks.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _KolomPerbandingan(
                            judul: 'Sebelum',
                            terpilih: sebelum,
                            pilihan: _riwayat,
                            onPilih: (r) =>
                                setDialogState(() => sebelum = r),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _KolomPerbandingan(
                            judul: 'Sesudah',
                            terpilih: sesudah,
                            pilihan: _riwayat,
                            onPilih: (r) =>
                                setDialogState(() => sesudah = r),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hst = _petak.umurHariSetelahTanam();
    final fase = _petak.faseTanam();

    final dataRiwayat = _riwayat.where((item) {
      if (_idMusim != null && item.idMusim != _idMusim) return false;
      if (_status != null && item.status != _status) return false;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Timeline ${_petak.nama}'),
        actions: [
          if (_riwayat.length >= 2)
            IconButton(
              tooltip: 'Bandingkan foto sebelum/sesudah',
              onPressed: _bandingkanFoto,
              icon: const Icon(Icons.compare_outlined),
            ),
          IconButton(
            tooltip: 'Edit lahan',
            onPressed: _editLahan,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: _memuat
          ? const Center(child: CircularProgressIndicator())
          : _galat != null
          ? KeadaanKosong(
              ikon: Icons.error_outline,
              judul: 'Timeline gagal dimuat',
              pesan: _galat!,
            )
          : RefreshIndicator(
              onRefresh: _muatSemua,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.horizontal,
                  AppSpacing.md,
                  AppSpacing.horizontal,
                  AppSpacing.xl,
                ),
                children: [
                  // Metadata Lahan & Umur Tanaman HST (PRD F-12 & S-12)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _petak.nama,
                                  style: context.teks.headlineSmall,
                                ),
                              ),
                              if (hst != null)
                                Lencana(
                                  teks: '$hst HST',
                                  warna: context.palet.primary,
                                  ikon: Icons.schedule_outlined,
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          if (_petak.lokasiCatatan.isNotEmpty)
                            Text(
                              _petak.lokasiCatatan,
                              style: context.teks.bodySmall,
                            ),
                          const Divider(height: AppSpacing.lg),
                          if (_petak.varietas.isNotEmpty)
                            BarisLabelNilai(
                              label: 'Varietas padi',
                              nilai: _petak.varietas,
                            ),
                          if (_petak.labelLuas != null)
                            BarisLabelNilai(
                              label: 'Luas lahan',
                              nilai: _petak.labelLuas!,
                            ),
                          if (_petak.tanggalTanam != null && hst != null) ...[
                            BarisLabelNilai(
                              label: 'Tanggal tanam',
                              nilai: FormatWaktu.panjang(_petak.tanggalTanam!),
                            ),
                            BarisLabelNilai(
                              label: 'Umur tanaman',
                              nilai: '$hst Hari Setelah Tanam (${fase ?? '-'})',
                            ),
                          ] else
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _editLahan,
                                icon: const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Isi Tanggal Tanam untuk Menghitung Umur Tanaman',
                                ),
                              ),
                            ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              FilledButton.icon(
                                onPressed: _memprosesAi
                                    ? null
                                    : _tambahPemeriksaanAi,
                                icon: const Icon(Icons.add_a_photo_outlined),
                                label: Text(
                                  _memprosesAi
                                      ? 'Memeriksa…'
                                      : 'Tambah Pemeriksaan',
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _formPengamatan(),
                                icon: const Icon(Icons.note_add_outlined),
                                label: const Text('Tambah Pengamatan'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _tambahJadwal,
                                icon: const Icon(Icons.event_available_outlined),
                                label: const Text('Tambah Jadwal'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Jadwal Perawatan Lahan (PRD F-16 & S-16)
                  if (_jadwal.isNotEmpty) ...[
                    Text('Jadwal Perawatan', style: context.teks.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    for (final item in _jadwal)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Card(
                          child: ListTile(
                            leading: Icon(
                              item.selesai
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked,
                              color: item.selesai
                                  ? context.palet.success
                                  : context.palet.primary,
                            ),
                            title: Text(
                              item.judul,
                              style: context.teks.titleSmall?.copyWith(
                                decoration: item.selesai
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: Text(
                              '${FormatWaktu.panjang(item.tanggalJadwal)}'
                              '${item.catatan.isNotEmpty ? ' · ${item.catatan}' : ''}',
                              style: context.teks.labelMedium,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: item.selesai
                                      ? 'Tandai belum selesai'
                                      : 'Tandai selesai',
                                  onPressed: () async {
                                    if (item.idJadwal == null) return;
                                    await widget.repository.ubahStatusJadwal(
                                      item.idJadwal!,
                                      !item.selesai,
                                    );
                                    await _muatSemua();
                                  },
                                  icon: const Icon(Icons.done_all, size: 20),
                                ),
                                IconButton(
                                  tooltip: 'Hapus jadwal',
                                  onPressed: () async {
                                    if (item.idJadwal == null) return;
                                    await widget.repository.hapusJadwal(
                                      item.idJadwal!,
                                    );
                                    await _muatSemua();
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Catatan Pengamatan Manual (PRD F-13 & S-13)
                  if (_pengamatan.isNotEmpty) ...[
                    Text(
                      'Catatan Pengamatan Manual',
                      style: context.teks.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final p in _pengamatan)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p.kondisiTanaman,
                                        style: context.teks.titleSmall,
                                      ),
                                    ),
                                    Text(
                                      FormatWaktu.angka(p.tanggal),
                                      style: context.teks.labelSmall,
                                    ),
                                    IconButton(
                                      tooltip: 'Edit pengamatan',
                                      onPressed: () =>
                                          _formPengamatan(awal: p),
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Hapus pengamatan',
                                      onPressed: () async {
                                        if (p.idPengamatan == null) return;
                                        await widget.repository.hapusPengamatan(
                                          p.idPengamatan!,
                                        );
                                        await _muatSemua();
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                if (p.gejalaDiamati.isNotEmpty)
                                  Text(
                                    'Gejala: ${p.gejalaDiamati}',
                                    style: context.teks.bodySmall,
                                  ),
                                if (p.tindakanDilakukan.isNotEmpty)
                                  Text(
                                    'Tindakan: ${p.tindakanDilakukan}',
                                    style: context.teks.bodySmall,
                                  ),
                                if (p.catatanTambahan.isNotEmpty)
                                  Text(
                                    'Catatan: ${p.catatanTambahan}',
                                    style: context.teks.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Kronologi Riwayat Identifikasi Lahan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Jumlah sampel diperiksa: ${dataRiwayat.length}',
                          style: context.teks.titleLarge,
                        ),
                      ),
                      if (_riwayat.length >= 2)
                        TextButton.icon(
                          onPressed: _bandingkanFoto,
                          icon: const Icon(Icons.compare_outlined, size: 18),
                          label: const Text('Bandingkan Foto'),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_riwayat.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            initialValue: _idMusim,
                            decoration: const InputDecoration(
                              labelText: 'Musim',
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Semua musim'),
                              ),
                              for (final item in _musim)
                                DropdownMenuItem(
                                  value: item.idMusim,
                                  child: Text(item.nama),
                                ),
                            ],
                            onChanged: (value) =>
                                setState(() => _idMusim = value),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: DropdownButtonFormField<StatusIdentifikasi?>(
                            initialValue: _status,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: null,
                                child: Text('Semua status'),
                              ),
                              DropdownMenuItem(
                                value: StatusIdentifikasi.terklasifikasi,
                                child: Text('Penyakit'),
                              ),
                              DropdownMenuItem(
                                value: StatusIdentifikasi.sehat,
                                child: Text('Sehat'),
                              ),
                              DropdownMenuItem(
                                value: StatusIdentifikasi.tidakPasti,
                                child: Text('Tidak pasti'),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _status = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (_riwayat.isEmpty)
                    const KeadaanKosong(
                      ikon: Icons.timeline_outlined,
                      judul: 'Belum ada pengamatan',
                      pesan:
                          'Mulai survei atau tekan Tambah Pemeriksaan untuk '
                          'membangun catatan perkembangan lahan.',
                    )
                  else if (dataRiwayat.isEmpty)
                    const KeadaanKosong(
                      ikon: Icons.filter_alt_off_outlined,
                      judul: 'Tidak ada yang cocok',
                      pesan: 'Ubah filter musim atau status.',
                    )
                  else
                    for (final item in dataRiwayat)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Card(
                          child: ListTile(
                            minVerticalPadding: AppSpacing.sm,
                            leading: Icon(
                              item.status == StatusIdentifikasi.tidakPasti
                                  ? Icons.help_outline
                                  : item.idPenyakit == 'normal'
                                  ? Icons.eco_outlined
                                  : Icons.coronavirus_outlined,
                            ),
                            title: Text(
                              item.penyakit?.nama ??
                                  (item.idPenyakit.isEmpty
                                      ? 'Hasil tidak pasti'
                                      : Penyakit.namaDariId(item.idPenyakit)),
                            ),
                            subtitle: Text(
                              '${FormatWaktu.panjang(item.waktu)} · '
                              '${(item.keyakinan * 100).toStringAsFixed(1)}%',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DetailRiwayatScreen(riwayat: item),
                                ),
                              );
                              if (mounted) await _muatSemua();
                            },
                          ),
                        ),
                      ),
                ],
              ),
            ),
    );
  }
}

class _KolomPerbandingan extends StatelessWidget {
  const _KolomPerbandingan({
    required this.judul,
    required this.terpilih,
    required this.pilihan,
    required this.onPilih,
  });

  final String judul;
  final Riwayat terpilih;
  final List<Riwayat> pilihan;
  final ValueChanged<Riwayat> onPilih;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(judul, style: context.teks.titleSmall),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.kecil),
          child: AspectRatio(
            aspectRatio: 1,
            child: ImageFile(path: terpilih.pathFoto),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButton<int>(
          isExpanded: true,
          value: terpilih.idRiwayat,
          items: [
            for (final r in pilihan)
              DropdownMenuItem<int>(
                value: r.idRiwayat,
                child: Text(
                  FormatWaktu.angka(r.waktu),
                  style: context.teks.labelSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (id) {
            final cocok = pilihan.where((r) => r.idRiwayat == id).firstOrNull;
            if (cocok != null) onPilih(cocok);
          },
        ),
        Text(
          terpilih.idPenyakit.isEmpty
              ? 'Tidak pasti'
              : Penyakit.namaDariId(terpilih.idPenyakit),
          style: context.teks.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '${(terpilih.keyakinan * 100).toStringAsFixed(1)}%',
          style: context.teks.labelSmall,
        ),
      ],
    );
  }
}
