import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/hasil_identifikasi.dart';
import '../models/penyakit.dart';
import '../theme/app_tokens.dart';
import '../utils/format_waktu.dart';
import '../widgets/komponen.dart';
import 'rekomendasi_screen.dart';

/// Detail satu entri riwayat (PRD F-09 & S-09).
///
/// Mendukung:
/// - Melihat foto, hasil, skor, tanggal, dan bukti audit model
/// - Menambahkan/mengubah catatan pengguna dan status penanganan
/// - Mengaitkan hasil dengan lahan (`Kelompokkan ke Petak`)
/// - Membuka rekomendasi penanganan atau menghapus riwayat
class DetailRiwayatScreen extends StatefulWidget {
  const DetailRiwayatScreen({super.key, required this.riwayat});

  final Riwayat riwayat;

  @override
  State<DetailRiwayatScreen> createState() => _DetailRiwayatScreenState();
}

class _DetailRiwayatScreenState extends State<DetailRiwayatScreen> {
  Penyakit? _penyakit;
  late String _catatan;
  late String _statusPenanganan;
  bool _memuat = true;

  @override
  void initState() {
    super.initState();
    _catatan = widget.riwayat.catatanPengguna;
    _statusPenanganan = widget.riwayat.statusPenanganan;
    _muat();
  }

  Future<void> _muat() async {
    if (widget.riwayat.idPenyakit.isNotEmpty) {
      try {
        _penyakit = await DatabaseHelper.instance.penyakitById(
          widget.riwayat.idPenyakit,
        );
      } on Object catch (e) {
        debugPrint('[DetailRiwayat] gagal memuat penyakit: $e');
        _penyakit = null;
      }
    }
    if (!mounted) return;
    setState(() => _memuat = false);
  }

  Future<void> _ubahCatatanDanStatus() async {
    final id = widget.riwayat.idRiwayat;
    if (id == null) return;
    final ctrl = TextEditingController(text: _catatan);
    String status = _statusPenanganan;

    final simpan = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Catatan & Status Penanganan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(
                  labelText: 'Status penanganan',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'belum_ditangani',
                    child: Text('Belum ditangani'),
                  ),
                  DropdownMenuItem(
                    value: 'dipantau',
                    child: Text('Sedang dipantau'),
                  ),
                  DropdownMenuItem(
                    value: 'sudah_ditangani',
                    child: Text('Sudah ditangani'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => status = v);
                },
              ),
              const SizedBox(height: AppSpacing.smPlus),
              TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Catatan pengamatan / tindakan',
                  hintText: 'Contoh: Sudah dilakukan sanitasi jerami dan pengairan berselang',
                ),
              ),
            ],
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

    if (simpan == true) {
      await DatabaseHelper.instance.perbaruiDetailRiwayat(
        idRiwayat: id,
        catatanPengguna: ctrl.text,
        statusPenanganan: status,
      );
      if (mounted) {
        setState(() {
          _catatan = ctrl.text.trim();
          _statusPenanganan = status;
        });
      }
    }
    ctrl.dispose();
  }

  Future<void> _hapus() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Riwayat Ini?'),
        content: const Text(
          'Entri riwayat ini beserta fotonya akan dihapus permanen. '
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
              minimumSize: const Size(88, 44),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (konfirmasi != true) return;

    final id = widget.riwayat.idRiwayat;
    if (id != null) {
      await DatabaseHelper.instance.hapusRiwayat(id);
    }
    await DatabaseHelper.instance.hapusFoto(widget.riwayat.pathFoto);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _kelompokkan() async {
    final id = widget.riwayat.idRiwayat;
    if (id == null) return;
    final petak = await DatabaseHelper.instance.semuaPetak();
    if (!mounted) return;
    if (petak.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan petak terlebih dahulu.')),
      );
      return;
    }
    final pilihan = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Kelompokkan ke petak'),
        children: [
          for (final item in petak)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, item.idPetak),
              child: Text(item.nama),
            ),
        ],
      ),
    );
    if (pilihan == null) return;
    final musim = await DatabaseHelper.instance.musimUntukPetak(pilihan);
    final aktif = musim.where((item) => item.aktif).firstOrNull;
    await DatabaseHelper.instance.kelompokkanRiwayat(
      idRiwayat: id,
      idPetak: pilihan,
      idMusim: aktif?.idMusim,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.riwayat;
    final dikenali = r.idPenyakit.isNotEmpty;
    final yakin = r.keyakinan * 100;
    final warna = dikenali
        ? context.warnaKeyakinan(yakin)
        : context.palet.mutedForeground;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Riwayat'),
        actions: [
          IconButton(
            tooltip: 'Edit catatan',
            onPressed: _ubahCatatanDanStatus,
            icon: const Icon(Icons.edit_note_outlined),
          ),
          IconButton(
            tooltip: 'Hapus riwayat ini',
            onPressed: _hapus,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: _memuat
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.horizontal,
                AppSpacing.md,
                AppSpacing.horizontal,
                AppSpacing.xl,
              ),
              children: [
                KartuFoto(
                  path: r.pathFoto,
                  labelSemantik: 'Foto riwayat identifikasi',
                ),
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.horizontal),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                dikenali
                                    ? (_penyakit?.nama ??
                                          Penyakit.namaDariId(r.idPenyakit))
                                    : 'Hasil Belum Meyakinkan',
                                style: context.teks.headlineSmall?.copyWith(
                                  color: warna,
                                ),
                              ),
                            ),
                            Lencana(
                              teks: dikenali
                                  ? (yakin >= 70 ? 'Dikenali' : 'Ragu')
                                  : 'Di bawah 70%',
                              warna: warna,
                              ikon: dikenali
                                  ? Icons.check_circle_outline
                                  : Icons.help_outline,
                            ),
                          ],
                        ),
                        if (_penyakit != null &&
                            _penyakit!.namaLatin.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _penyakit!.namaLatin,
                            style: context.teks.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const Divider(height: AppSpacing.lg),
                        BarisLabelNilai(
                          label: 'Tingkat keyakinan',
                          nilai: '${yakin.toStringAsFixed(2)}%',
                        ),
                        BarisLabelNilai(
                          label: 'Tanggal',
                          nilai: FormatWaktu.panjang(r.waktu),
                        ),
                        BarisLabelNilai(
                          label: 'Jam',
                          nilai: FormatWaktu.ringkas(r.waktu).split(', ').last,
                        ),
                        if (r.namaPetak != null && r.namaPetak!.isNotEmpty)
                          BarisLabelNilai(
                            label: 'Lahan',
                            nilai: r.namaPetak!,
                          ),
                        BarisLabelNilai(
                          label: 'Status penanganan',
                          nilai: Riwayat.labelStatusPenanganan(
                            _statusPenanganan,
                          ),
                        ),
                        if (_catatan.isNotEmpty)
                          BarisLabelNilai(
                            label: 'Catatan pengguna',
                            nilai: _catatan,
                          ),
                        if (!dikenali) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Hasil belum cukup meyakinkan (di bawah ambang '
                            'batas 70%), sehingga aplikasi tidak menampilkan '
                            'diagnosis.',
                            style: context.teks.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                KartuBagian(
                  judul: 'Bukti audit',
                  ikon: Icons.fact_check_outlined,
                  anak: Column(
                    children: [
                      BarisLabelNilai(label: 'Model', nilai: r.modelVersion),
                      BarisLabelNilai(
                        label: 'Aturan',
                        nilai: r.aturan.isEmpty ? 'Tidak tercatat' : r.aturan,
                      ),
                      BarisLabelNilai(
                        label: 'Prapemrosesan',
                        nilai: r.auditTersedia
                            ? '${r.waktuPraprosesMs} ms'
                            : 'Tidak dicatat',
                      ),
                      BarisLabelNilai(
                        label: 'Inferensi model',
                        nilai: r.auditTersedia
                            ? '${r.waktuInferensiMs} ms'
                            : 'Tidak dicatat',
                      ),
                      BarisLabelNilai(
                        label: 'Total proses',
                        nilai: r.auditTersedia
                            ? '${r.waktuTotalMs} ms'
                            : 'Tidak dicatat',
                      ),
                      BarisLabelNilai(
                        label: 'Kualitas foto',
                        nilai: !r.auditTersedia
                            ? 'Tidak dicatat'
                            : r.fotoGelap
                            ? 'Foto terlalu gelap'
                            : r.fotoBuram
                            ? 'Foto berpotensi buram'
                            : 'Tidak ada peringatan',
                      ),
                      if (r.idPetak != null)
                        BarisLabelNilai(
                          label: 'Petak / musim / sesi',
                          nilai:
                              '${r.idPetak} / ${r.idMusim ?? '-'} / '
                              '${r.idSesi ?? '-'}',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: _ubahCatatanDanStatus,
                  icon: const Icon(Icons.edit_note_outlined),
                  label: const Text('Ubah Catatan & Status Penanganan'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _kelompokkan,
                  icon: const Icon(Icons.drive_file_move_outline),
                  label: Text(
                    r.idPetak == null
                        ? 'Kelompokkan ke Petak'
                        : 'Pindahkan ke Petak Lain',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_penyakit != null)
                  Semantics(
                    button: true,
                    label: _penyakit!.isSehat
                        ? 'Lihat saran pemeliharaan'
                        : 'Lihat rekomendasi penanganan',
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              RekomendasiScreen(penyakit: _penyakit!),
                        ),
                      ),
                      icon: Icon(
                        _penyakit!.isSehat
                            ? Icons.verified_outlined
                            : Icons.medical_information_outlined,
                      ),
                      label: Text(
                        _penyakit!.isSehat
                            ? 'Lihat Saran Pemeliharaan'
                            : 'Lihat Rekomendasi Penanganan',
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
