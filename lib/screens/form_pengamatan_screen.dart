import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/catatan_lapangan_repository.dart';
import '../data/database_helper.dart';
import '../models/catatan_lapangan.dart';
import '../models/hasil_identifikasi.dart';
import '../models/penyakit.dart';
import '../theme/app_tokens.dart';
import '../utils/format_waktu.dart';
import '../widgets/komponen.dart';

/// Layar Form Catatan Pengamatan Manual sesuai PRD F-13 dan S-13.
///
/// Mendukung:
/// - Pemilihan Lahan (`idPetak`)
/// - Tanggal pengamatan (`tanggal`)
/// - Foto opsional dari Kamera atau Galeri (`pathFoto`)
/// - Kondisi tanaman (`kondisiTanaman`)
/// - Gejala yang diamati (`gejalaDiamati`)
/// - Tindakan yang dilakukan (`tindakanDilakukan`)
/// - Catatan tambahan (`catatanTambahan`)
/// - Pengaitan opsional dengan hasil identifikasi (`idRiwayat`)
class FormPengamatanScreen extends StatefulWidget {
  const FormPengamatanScreen({
    super.key,
    this.idPetakAwal,
    this.pengamatanAwal,
    this.repository = const DatabaseCatatanLapanganRepository(),
  });

  final int? idPetakAwal;
  final CatatanPengamatan? pengamatanAwal;
  final CatatanLapanganRepository repository;

  @override
  State<FormPengamatanScreen> createState() => _FormPengamatanScreenState();
}

class _FormPengamatanScreenState extends State<FormPengamatanScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _kondisiCtrl;
  late final TextEditingController _gejalaCtrl;
  late final TextEditingController _tindakanCtrl;
  late final TextEditingController _catatanCtrl;

  List<Petak> _daftarLahan = const [];
  List<Riwayat> _daftarRiwayatLahan = const [];
  int? _idPetak;
  int? _idRiwayat;
  late DateTime _tanggal;
  String? _pathFoto;
  bool _memuat = true;
  bool _menyimpan = false;

  static const _opsiKondisiCepat = <String>[
    'Pertumbuhan normal, daun tampak sehat',
    'Gejala bercak berkurang setelah tindakan',
    'Muncul gejala baru pada beberapa rumpun',
    'Perlu pemantauan ulang 3–5 hari ke depan',
  ];

  @override
  void initState() {
    super.initState();
    final awal = widget.pengamatanAwal;
    _idPetak = awal?.idPetak ?? widget.idPetakAwal;
    _idRiwayat = awal?.idRiwayat;
    _tanggal = awal?.tanggal ?? DateTime.now();
    _pathFoto = awal?.pathFoto;
    _kondisiCtrl = TextEditingController(
      text: awal?.kondisiTanaman ?? _opsiKondisiCepat.first,
    );
    _gejalaCtrl = TextEditingController(text: awal?.gejalaDiamati ?? '');
    _tindakanCtrl = TextEditingController(text: awal?.tindakanDilakukan ?? '');
    _catatanCtrl = TextEditingController(text: awal?.catatanTambahan ?? '');
    _muatDataPendukung();
  }

  @override
  void dispose() {
    _kondisiCtrl.dispose();
    _gejalaCtrl.dispose();
    _tindakanCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _muatDataPendukung() async {
    try {
      final lahan = await widget.repository.semuaPetak();
      final idTerpilih = _idPetak ?? (lahan.isNotEmpty ? lahan.first.idPetak : null);
      List<Riwayat> riwayat = const [];
      if (idTerpilih != null) {
        riwayat = await widget.repository.timelinePetak(idTerpilih);
      }
      if (!mounted) return;
      setState(() {
        _daftarLahan = lahan;
        _idPetak = idTerpilih;
        _daftarRiwayatLahan = riwayat;
        if (_idRiwayat != null &&
            !_daftarRiwayatLahan.any((r) => r.idRiwayat == _idRiwayat)) {
          _idRiwayat = null;
        }
        _memuat = false;
      });
    } on Object catch (e) {
      debugPrint('[FormPengamatan] gagal memuat data: $e');
      if (mounted) setState(() => _memuat = false);
    }
  }

  Future<void> _ubahLahan(int? idBaru) async {
    setState(() {
      _idPetak = idBaru;
      _idRiwayat = null;
    });
    if (idBaru == null) return;
    try {
      final riwayat = await widget.repository.timelinePetak(idBaru);
      if (mounted) {
        setState(() => _daftarRiwayatLahan = riwayat);
      }
    } on Object catch (e) {
      debugPrint('[FormPengamatan] gagal memuat riwayat lahan: $e');
    }
  }

  Future<void> _pilihTanggal() async {
    final pilih = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _tanggal,
    );
    if (pilih != null && mounted) {
      setState(() => _tanggal = pilih);
    }
  }

  Future<void> _ambilFotoOpsional(ImageSource sumber) async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: sumber,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );
      if (foto == null || !mounted) return;
      final tersimpan = await DatabaseHelper.instance.salinFotoKeAplikasi(
        foto.path,
      );
      if (!mounted) return;
      setState(() => _pathFoto = tersimpan);
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal melampirkan foto: $e')));
    }
  }

  Future<void> _simpan() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_idPetak == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih lahan terlebih dahulu.')),
      );
      return;
    }

    setState(() => _menyimpan = true);
    try {
      await widget.repository.simpanPengamatan(
        CatatanPengamatan(
          idPengamatan: widget.pengamatanAwal?.idPengamatan,
          idPetak: _idPetak!,
          idRiwayat: _idRiwayat,
          tanggal: _tanggal,
          kondisiTanaman: _kondisiCtrl.text.trim(),
          gejalaDiamati: _gejalaCtrl.text.trim(),
          tindakanDilakukan: _tindakanCtrl.text.trim(),
          catatanTambahan: _catatanCtrl.text.trim(),
          pathFoto: _pathFoto,
          dibuatPada: widget.pengamatanAwal?.dibuatPada ?? DateTime.now(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan pengamatan: $e')));
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final edit = widget.pengamatanAwal != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(edit ? 'Edit Catatan Pengamatan' : 'Catatan Pengamatan'),
      ),
      body: _memuat
          ? const Center(child: CircularProgressIndicator())
          : _daftarLahan.isEmpty
          ? const KeadaanKosong(
              ikon: Icons.grass_outlined,
              judul: 'Belum ada lahan terdaftar',
              pesan:
                  'Tambahkan lahan terlebih dahulu pada menu Lahan Saya sebelum '
                  'mencatat pengamatan lapangan.',
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.horizontal,
                  AppSpacing.md,
                  AppSpacing.horizontal,
                  AppSpacing.xl,
                ),
                children: [
                  Text(
                    'Catat kondisi tanaman di lapangan secara berkala tanpa '
                    'harus menjalankan identifikasi AI.',
                    style: context.teks.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<int>(
                    initialValue: _idPetak,
                    decoration: const InputDecoration(
                      labelText: 'Lahan',
                      prefixIcon: Icon(Icons.grass_outlined),
                    ),
                    items: [
                      for (final l in _daftarLahan)
                        if (l.idPetak != null)
                          DropdownMenuItem<int>(
                            value: l.idPetak,
                            child: Text(l.nama),
                          ),
                    ],
                    onChanged: _ubahLahan,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: _pilihTanggal,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tanggal pengamatan: ${FormatWaktu.panjang(_tanggal)}',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Kondisi tanaman + chip cepat
                  TextFormField(
                    controller: _kondisiCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Kondisi tanaman',
                      hintText:
                          'Contoh: Daun mulai menghijau / gejala berkurang',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Kondisi tanaman wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final opsi in _opsiKondisiCepat)
                        ActionChip(
                          label: Text(opsi, style: context.teks.labelSmall),
                          onPressed: () =>
                              setState(() => _kondisiCtrl.text = opsi),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  TextFormField(
                    controller: _gejalaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Gejala yang diamati (opsional)',
                      hintText:
                          'Contoh: Bercak belah ketupat pada 3 rumpun tepi timur',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  TextFormField(
                    controller: _tindakanCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tindakan yang dilakukan (opsional)',
                      hintText:
                          'Contoh: Pengairan berselang & pembersihan gulma pematang',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (_daftarRiwayatLahan.isNotEmpty) ...[
                    DropdownButtonFormField<int?>(
                      initialValue: _idRiwayat,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText:
                            'Kaitkan dengan hasil identifikasi (opsional)',
                        prefixIcon: Icon(Icons.link_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Tidak dikaitkan'),
                        ),
                        for (final r in _daftarRiwayatLahan)
                          if (r.idRiwayat != null)
                            DropdownMenuItem<int?>(
                              value: r.idRiwayat,
                              child: Text(
                                '${FormatWaktu.angka(r.waktu)} · '
                                '${r.idPenyakit.isEmpty ? "Belum meyakinkan" : Penyakit.namaDariId(r.idPenyakit)}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                      ],
                      onChanged: (v) => setState(() => _idRiwayat = v),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  TextFormField(
                    controller: _catatanCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Catatan tambahan (opsional)',
                      hintText: 'Catatan cuaca, tinggi genangan air, dsb.',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Lampiran Foto Opsional (PRD F-13 & S-13)
                  KartuBagian(
                    judul: 'Foto Pengamatan (Opsional)',
                    ikon: Icons.photo_camera_outlined,
                    anak: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_pathFoto != null && _pathFoto!.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppRadius.kecil,
                            ),
                            child: AspectRatio(
                              aspectRatio: 16 / 10,
                              child: ImageFile(path: _pathFoto!),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton.icon(
                            onPressed: () => setState(() => _pathFoto = null),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Hapus Foto Lampiran'),
                          ),
                        ] else
                          Text(
                            'Lampirkan foto kondisi tanaman atau lahan untuk '
                            'memudahkan pemantauan perkembangan sebelum/sesudah.',
                            style: context.teks.bodySmall,
                          ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _ambilFotoOpsional(ImageSource.camera),
                                icon: const Icon(Icons.photo_camera_outlined),
                                label: const Text('Kamera'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _ambilFotoOpsional(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('Galeri'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  FilledButton.icon(
                    onPressed: _menyimpan ? null : _simpan,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(
                      _menyimpan ? 'Menyimpan…' : 'Simpan Catatan Pengamatan',
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
