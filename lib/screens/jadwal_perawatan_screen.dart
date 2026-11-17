import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/catatan_lapangan.dart';
import '../theme/app_tokens.dart';
import '../utils/format_waktu.dart';
import '../widgets/komponen.dart';

/// Layar Jadwal Perawatan & Kalender Tanam Sederhana (PRD F-16, F-17, F-26, S-16).
///
/// Menampilkan:
/// - Kalender tanam sederhana (umur tanaman HST, estimasi fase pertumbuhan,
///   dan tonggak kegiatan perawatan utama)
/// - Daftar kegiatan mendatang (`pending`)
/// - Daftar kegiatan selesai (`completed`)
/// - Form tambah jadwal lengkap (Nama kegiatan, Lahan, Tanggal, Waktu opsional,
///   Catatan, dan Pengingat lokal)
class JadwalPerawatanScreen extends StatefulWidget {
  const JadwalPerawatanScreen({super.key, this.idPetakAwal});

  final int? idPetakAwal;

  @override
  State<JadwalPerawatanScreen> createState() => _JadwalPerawatanScreenState();
}

class _JadwalPerawatanScreenState extends State<JadwalPerawatanScreen> {
  List<Petak> _daftarLahan = const [];
  List<JadwalPerawatan> _daftarJadwal = const [];
  int? _filterPetak;
  bool _memuat = true;

  @override
  void initState() {
    super.initState();
    _filterPetak = widget.idPetakAwal;
    _muatData();
  }

  Future<void> _muatData() async {
    setState(() => _memuat = true);
    try {
      final lahan = await DatabaseHelper.instance.semuaPetak();
      final jadwal = await DatabaseHelper.instance.semuaJadwal(
        idPetak: _filterPetak,
      );
      if (!mounted) return;
      setState(() {
        _daftarLahan = lahan;
        _daftarJadwal = jadwal;
        _memuat = false;
      });
    } on Object catch (e) {
      debugPrint('[JadwalPerawatan] gagal memuat: $e');
      if (mounted) setState(() => _memuat = false);
    }
  }

  Future<void> _bukaFormTambahJadwal() async {
    if (_daftarLahan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan lahan terlebih dahulu pada menu Lahan Saya.'),
        ),
      );
      return;
    }

    int idPetak = _filterPetak ?? _daftarLahan.first.idPetak!;
    String jenis = JadwalPerawatan.jenisKegiatanAwal.first;
    final judulKustomCtrl = TextEditingController();
    final catatanCtrl = TextEditingController();
    DateTime tanggal = DateTime.now().add(const Duration(days: 3));
    TimeOfDay? waktuOpsional = const TimeOfDay(hour: 7, minute: 0);
    bool pengingatAktif = true;

    final simpan = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.horizontal,
              AppSpacing.md,
              AppSpacing.horizontal,
              MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.md,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tambah Jadwal Perawatan',
                    style: ctx.teks.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Jadwalkan kegiatan pemeriksaan atau perawatan lahan padi.',
                    style: ctx.teks.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<int>(
                    initialValue: idPetak,
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
                    onChanged: (v) {
                      if (v != null) setModalState(() => idPetak = v);
                    },
                  ),
                  const SizedBox(height: AppSpacing.smPlus),
                  DropdownButtonFormField<String>(
                    initialValue: jenis,
                    decoration: const InputDecoration(
                      labelText: 'Nama kegiatan',
                      prefixIcon: Icon(Icons.task_alt_outlined),
                    ),
                    items: [
                      for (final k in JadwalPerawatan.jenisKegiatanAwal)
                        DropdownMenuItem(value: k, child: Text(k)),
                    ],
                    onChanged: (v) {
                      if (v != null) setModalState(() => jenis = v);
                    },
                  ),
                  if (jenis == 'Kegiatan lain') ...[
                    const SizedBox(height: AppSpacing.smPlus),
                    TextField(
                      controller: judulKustomCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Sebutkan nama kegiatan',
                        hintText: 'Contoh: Sanitasi saluran irigasi',
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.smPlus),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final pilih = await showDatePicker(
                              context: ctx,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 30),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                              initialDate: tanggal,
                            );
                            if (pilih != null) {
                              setModalState(() => tanggal = pilih);
                            }
                          },
                          icon: const Icon(Icons.event_outlined, size: 18),
                          label: Text(FormatWaktu.angka(tanggal)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final pilih = await showTimePicker(
                              context: ctx,
                              initialTime:
                                  waktuOpsional ??
                                  const TimeOfDay(hour: 7, minute: 0),
                            );
                            if (pilih != null) {
                              setModalState(() => waktuOpsional = pilih);
                            }
                          },
                          icon: const Icon(Icons.access_time_outlined, size: 18),
                          label: Text(
                            waktuOpsional == null
                                ? 'Waktu (opsional)'
                                : '${waktuOpsional!.hour.toString().padLeft(2, '0')}:${waktuOpsional!.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.smPlus),
                  TextField(
                    controller: catatanCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)',
                      hintText:
                          'Contoh: Periksa daun bendera pada petak bagian utara',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Aktifkan pengingat lokal',
                      style: ctx.teks.titleSmall,
                    ),
                    subtitle: Text(
                      'Tampilkan sebagai jadwal prioritas pada Beranda.',
                      style: ctx.teks.labelSmall,
                    ),
                    value: pengingatAktif,
                    onChanged: (v) => setModalState(() => pengingatAktif = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Simpan Jadwal'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (simpan == true) {
      final tanggalLengkap = DateTime(
        tanggal.year,
        tanggal.month,
        tanggal.day,
        waktuOpsional?.hour ?? 7,
        waktuOpsional?.minute ?? 0,
      );
      final judulFinal =
          (jenis == 'Kegiatan lain' && judulKustomCtrl.text.trim().isNotEmpty)
          ? judulKustomCtrl.text.trim()
          : jenis;

      await DatabaseHelper.instance.simpanJadwal(
        JadwalPerawatan(
          idPetak: idPetak,
          judul: judulFinal,
          catatan: catatanCtrl.text.trim(),
          tanggalJadwal: tanggalLengkap,
          pengingatAktif: pengingatAktif,
        ),
      );
      if (mounted) await _muatData();
    }

    judulKustomCtrl.dispose();
    catatanCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mendatang = _daftarJadwal.where((j) => !j.selesai).toList();
    final selesai = _daftarJadwal.where((j) => j.selesai).toList();
    final lahanTerpilih = _filterPetak != null
        ? _daftarLahan.where((l) => l.idPetak == _filterPetak).firstOrNull
        : (_daftarLahan.length == 1 ? _daftarLahan.first : null);

    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Perawatan')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _bukaFormTambahJadwal,
        icon: const Icon(Icons.add_task_outlined),
        label: const Text('Tambah Jadwal'),
      ),
      body: _memuat
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _muatData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.horizontal,
                  AppSpacing.md,
                  AppSpacing.horizontal,
                  96,
                ),
                children: [
                  if (_daftarLahan.length > 1) ...[
                    DropdownButtonFormField<int?>(
                      initialValue: _filterPetak,
                      decoration: const InputDecoration(
                        labelText: 'Filter lahan',
                        prefixIcon: Icon(Icons.grass_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Semua Lahan'),
                        ),
                        for (final l in _daftarLahan)
                          DropdownMenuItem<int?>(
                            value: l.idPetak,
                            child: Text(l.nama),
                          ),
                      ],
                      onChanged: (v) {
                        setState(() => _filterPetak = v);
                        _muatData();
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Kalender Tanam Sederhana (PRD F-26)
                  if (lahanTerpilih != null) ...[
                    _KartuKalenderTanam(petak: lahanTerpilih),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Daftar kegiatan mendatang (PRD S-16)
                  Text(
                    'Kegiatan Mendatang (${mendatang.length})',
                    style: context.teks.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (mendatang.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          'Belum ada jadwal kegiatan mendatang. Tekan tombol '
                          '"Tambah Jadwal" untuk menjadwalkan pemeriksaan daun, '
                          'pemupukan, atau pengairan.',
                          style: context.teks.bodySmall,
                        ),
                      ),
                    )
                  else
                    for (final item in mendatang)
                      _KartuItemJadwal(
                        item: item,
                        onToggleSelesai: () async {
                          if (item.idJadwal == null) return;
                          await DatabaseHelper.instance.ubahStatusJadwal(
                            item.idJadwal!,
                            true,
                          );
                          await _muatData();
                        },
                        onHapus: () async {
                          if (item.idJadwal == null) return;
                          await DatabaseHelper.instance.hapusJadwal(
                            item.idJadwal!,
                          );
                          await _muatData();
                        },
                      ),

                  const SizedBox(height: AppSpacing.lg),

                  // Daftar kegiatan selesai (PRD S-16)
                  Text(
                    'Kegiatan Selesai (${selesai.length})',
                    style: context.teks.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (selesai.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          'Belum ada kegiatan yang ditandai selesai.',
                          style: context.teks.bodySmall,
                        ),
                      ),
                    )
                  else
                    for (final item in selesai)
                      _KartuItemJadwal(
                        item: item,
                        onToggleSelesai: () async {
                          if (item.idJadwal == null) return;
                          await DatabaseHelper.instance.ubahStatusJadwal(
                            item.idJadwal!,
                            false,
                          );
                          await _muatData();
                        },
                        onHapus: () async {
                          if (item.idJadwal == null) return;
                          await DatabaseHelper.instance.hapusJadwal(
                            item.idJadwal!,
                          );
                          await _muatData();
                        },
                      ),
                ],
              ),
            ),
    );
  }
}

class _KartuKalenderTanam extends StatelessWidget {
  const _KartuKalenderTanam({required this.petak});

  final Petak petak;

  @override
  Widget build(BuildContext context) {
    final hst = petak.umurHariSetelahTanam();
    final fase = petak.faseTanam();

    return KartuBagian(
      judul: 'Kalender Tanam — ${petak.nama}',
      ikon: Icons.calendar_month_outlined,
      anak: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (petak.tanggalTanam == null || hst == null)
            Text(
              'Tanggal tanam belum diisi pada lahan ini. Isi tanggal tanam di '
              'menu Edit Lahan untuk melihat umur tanaman (HST) dan estimasi '
              'fase pertumbuhan.',
              style: context.teks.bodySmall,
            )
          else ...[
            BarisLabelNilai(
              label: 'Tanggal tanam',
              nilai: FormatWaktu.panjang(petak.tanggalTanam!),
            ),
            BarisLabelNilai(
              label: 'Umur tanaman saat ini',
              nilai: '$hst Hari Setelah Tanam (HST)',
            ),
            BarisLabelNilai(
              label: 'Estimasi fase pertumbuhan',
              nilai: fase ?? '-',
            ),
            const Divider(height: AppSpacing.lg),
            Text(
              'Acuan Kegiatan Berdasarkan Umur Tanaman (HST):',
              style: context.teks.titleSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '• 0–35 HST (Vegetatif Awal): Pengamatan gejala kresek/HDB & pemupukan dasar.\n'
              '• 36–55 HST (Vegetatif Akhir): Pengairan berselang & pemeriksaan blas daun.\n'
              '• 56–85 HST (Generatif): Pengamatan daun bendera & pencegahan blas leher.\n'
              '• >85 HST (Pemasakan): Pengeringan bertahap menjelang panen.',
              style: context.teks.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _KartuItemJadwal extends StatelessWidget {
  const _KartuItemJadwal({
    required this.item,
    required this.onToggleSelesai,
    required this.onHapus,
  });

  final JadwalPerawatan item;
  final VoidCallback onToggleSelesai;
  final VoidCallback onHapus;

  @override
  Widget build(BuildContext context) {
    final jam =
        '${item.tanggalJadwal.hour.toString().padLeft(2, '0')}:'
        '${item.tanggalJadwal.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: IconButton(
          tooltip: item.selesai
              ? 'Tandai belum selesai'
              : 'Tandai kegiatan selesai',
          onPressed: onToggleSelesai,
          icon: Icon(
            item.selesai
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            color: item.selesai
                ? context.palet.success
                : context.palet.primary,
          ),
        ),
        title: Text(
          item.judul,
          style: context.teks.titleSmall?.copyWith(
            decoration: item.selesai ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${FormatWaktu.panjang(item.tanggalJadwal)} ($jam)'
          '${item.namaPetak != null ? ' · ${item.namaPetak}' : ''}'
          '${item.catatan.isNotEmpty ? '\n${item.catatan}' : ''}',
          style: context.teks.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.pengingatAktif && !item.selesai)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.notifications_active_outlined,
                  size: 18,
                  color: context.palet.primary,
                ),
              ),
            IconButton(
              tooltip: 'Hapus jadwal',
              onPressed: onHapus,
              icon: const Icon(Icons.delete_outline, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
