import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/catatan_lapangan.dart';
import '../models/hasil_identifikasi.dart';
import '../models/penyakit.dart';
import '../theme/app_tokens.dart';
import '../utils/format_waktu.dart';
import '../widgets/komponen.dart';

/// Layar Monitoring Perkembangan Tanaman & Perbandingan Foto Sebelum/Sesudah
/// sesuai PRD F-18, F-19, dan S-17.
///
/// Menampilkan:
/// - Pilihan Lahan (atau lahan spesifik)
/// - Perbandingan Foto Sebelum/Sesudah berdampingan
/// - Catatan tindakan yang dilakukan
/// - Kronologi gabungan pengamatan manual & hasil identifikasi AI
/// - Pernyataan eksplisit bahwa sistem tidak otomatis menyimpulkan kesembuhan
///   tanaman tanpa metrik yang terukur.
class MonitoringPerkembanganScreen extends StatefulWidget {
  const MonitoringPerkembanganScreen({super.key, this.idPetakAwal});

  final int? idPetakAwal;

  @override
  State<MonitoringPerkembanganScreen> createState() =>
      _MonitoringPerkembanganScreenState();
}

class _ButirKronologi {
  final String idUnik;
  final DateTime tanggal;
  final String judul;
  final String subjudul;
  final String tindakan;
  final String catatan;
  final String? pathFoto;
  final bool adalahAi;

  const _ButirKronologi({
    required this.idUnik,
    required this.tanggal,
    required this.judul,
    required this.subjudul,
    this.tindakan = '',
    this.catatan = '',
    this.pathFoto,
    required this.adalahAi,
  });
}

class _MonitoringPerkembanganScreenState
    extends State<MonitoringPerkembanganScreen> {
  List<Petak> _daftarLahan = const [];
  List<_ButirKronologi> _kronologi = const [];
  int? _idPetakTerpilih;
  String? _idSebelum;
  String? _idSesudah;
  bool _memuat = true;

  @override
  void initState() {
    super.initState();
    _idPetakTerpilih = widget.idPetakAwal;
    _muatData();
  }

  Future<void> _muatData() async {
    setState(() => _memuat = true);
    try {
      final lahan = await DatabaseHelper.instance.semuaPetak();
      final idTarget =
          _idPetakTerpilih ?? (lahan.isNotEmpty ? lahan.first.idPetak : null);

      List<Riwayat> riwayat = const [];
      List<CatatanPengamatan> pengamatan = const [];
      if (idTarget != null) {
        riwayat = await DatabaseHelper.instance.timelinePetak(idTarget);
        pengamatan = await DatabaseHelper.instance.pengamatanUntukPetak(
          idTarget,
        );
      } else {
        riwayat = await DatabaseHelper.instance.semuaRiwayat();
        pengamatan = await DatabaseHelper.instance.semuaPengamatan();
      }

      final gabungan = <_ButirKronologi>[
        for (final r in riwayat)
          _ButirKronologi(
            idUnik: 'ai_${r.idRiwayat ?? r.waktu.millisecondsSinceEpoch}',
            tanggal: r.waktu,
            judul: r.idPenyakit.isEmpty
                ? 'Pemeriksaan AI: Belum meyakinkan (<70%)'
                : 'Pemeriksaan AI: ${Penyakit.namaDariId(r.idPenyakit)}',
            subjudul:
                'Skor model ${(r.keyakinan * 100).toStringAsFixed(1)}% · '
                '${Riwayat.labelStatusPenanganan(r.statusPenanganan)}',
            catatan: r.catatanPengguna,
            pathFoto: r.pathFoto.isNotEmpty ? r.pathFoto : null,
            adalahAi: true,
          ),
        for (final p in pengamatan)
          _ButirKronologi(
            idUnik: 'obs_${p.idPengamatan ?? p.tanggal.millisecondsSinceEpoch}',
            tanggal: p.tanggal,
            judul: 'Pengamatan: ${p.kondisiTanaman}',
            subjudul: p.gejalaDiamati.isNotEmpty
                ? 'Gejala: ${p.gejalaDiamati}'
                : 'Catatan pengamatan lapangan',
            tindakan: p.tindakanDilakukan,
            catatan: p.catatanTambahan,
            pathFoto: p.pathFoto,
            adalahAi: false,
          ),
      ]..sort((a, b) => b.tanggal.compareTo(a.tanggal));

      final berfoto = gabungan
          .where((b) => b.pathFoto != null && b.pathFoto!.isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        _daftarLahan = lahan;
        _idPetakTerpilih = idTarget;
        _kronologi = gabungan;
        if (berfoto.length >= 2) {
          _idSebelum = berfoto.last.idUnik;
          _idSesudah = berfoto.first.idUnik;
        } else {
          _idSebelum = null;
          _idSesudah = null;
        }
        _memuat = false;
      });
    } on Object catch (e) {
      debugPrint('[Monitoring] gagal memuat: $e');
      if (mounted) setState(() => _memuat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final berfoto = _kronologi
        .where((b) => b.pathFoto != null && b.pathFoto!.isNotEmpty)
        .toList();
    final sebelum = berfoto.where((b) => b.idUnik == _idSebelum).firstOrNull;
    final sesudah = berfoto.where((b) => b.idUnik == _idSesudah).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Monitoring Perkembangan')),
      body: _memuat
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _muatData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.horizontal,
                  AppSpacing.md,
                  AppSpacing.horizontal,
                  AppSpacing.xl,
                ),
                children: [
                  if (_daftarLahan.isNotEmpty) ...[
                    DropdownButtonFormField<int?>(
                      initialValue: _idPetakTerpilih,
                      decoration: const InputDecoration(
                        labelText: 'Pilih lahan yang dipantau',
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
                        setState(() => _idPetakTerpilih = v);
                        _muatData();
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Peringatan wajib PRD S-17 & F-18
                  KartuPesan(
                    warna: context.palet.primary,
                    ikon: Icons.info_outline,
                    judul: 'Pemantauan Visual & Catatan Lapangan',
                    isi:
                        'Sistem tidak otomatis menyatakan peningkatan kondisi '
                        'tanaman tanpa bukti atau metrik yang terukur. Gunakan '
                        'perbandingan foto dan catatan tindakan untuk evaluasi bersama penyuluh.',
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Perbandingan Foto Sebelum / Sesudah (PRD F-19 & S-17)
                  KartuBagian(
                    judul: 'Perbandingan Foto Sebelum / Sesudah',
                    ikon: Icons.compare_outlined,
                    anak: berfoto.length < 2
                        ? Text(
                            'Diperlukan minimal 2 pemeriksaan atau pengamatan '
                            'berfoto pada lahan ini untuk membandingkan kondisi '
                            'sebelum dan sesudah penanganan.',
                            style: context.teks.bodySmall,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _KolomFotoMonitoring(
                                        label: 'Sebelum',
                                        terpilih: sebelum ?? berfoto.last,
                                        pilihan: berfoto,
                                        onPilih: (id) =>
                                            setState(() => _idSebelum = id),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: _KolomFotoMonitoring(
                                        label: 'Sesudah',
                                        terpilih: sesudah ?? berfoto.first,
                                        pilihan: berfoto,
                                        onPilih: (id) =>
                                            setState(() => _idSesudah = id),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Kronologi pengamatan & tindakan (PRD S-17)
                  Text(
                    'Kronologi Pengamatan & Pemeriksaan (${_kronologi.length})',
                    style: context.teks.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_kronologi.isEmpty)
                    const KeadaanKosong(
                      ikon: Icons.timeline_outlined,
                      judul: 'Belum ada kronologi pemantauan',
                      pesan:
                          'Tambahkan pemeriksaan daun AI atau catatan pengamatan '
                          'manual untuk memantau perkembangan kondisi tanaman.',
                    )
                  else
                    for (final item in _kronologi)
                      Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.smPlus),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Lencana(
                                    teks: item.adalahAi
                                        ? 'Identifikasi AI'
                                        : 'Pengamatan Manual',
                                    warna: item.adalahAi
                                        ? context.palet.primary
                                        : context.palet.success,
                                    ikon: item.adalahAi
                                        ? Icons.memory_rounded
                                        : Icons.visibility_outlined,
                                  ),
                                  const Spacer(),
                                  Text(
                                    FormatWaktu.ringkas(item.tanggal),
                                    style: context.teks.labelSmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                item.judul,
                                style: context.teks.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.subjudul,
                                style: context.teks.bodySmall,
                              ),
                              if (item.tindakan.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Tindakan: ${item.tindakan}',
                                  style: context.teks.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (item.catatan.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Catatan: ${item.catatan}',
                                  style: context.teks.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
    );
  }
}

class _KolomFotoMonitoring extends StatelessWidget {
  const _KolomFotoMonitoring({
    required this.label,
    required this.terpilih,
    required this.pilihan,
    required this.onPilih,
  });

  final String label;
  final _ButirKronologi terpilih;
  final List<_ButirKronologi> pilihan;
  final ValueChanged<String> onPilih;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.palet.background,
        borderRadius: BorderRadius.circular(AppRadius.kecil),
        border: Border.all(color: context.palet.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.teks.labelMedium),
          const SizedBox(height: 4),
          DropdownButton<String>(
            value: terpilih.idUnik,
            isExpanded: true,
            items: [
              for (final p in pilihan)
                DropdownMenuItem<String>(
                  value: p.idUnik,
                  child: Text(
                    FormatWaktu.angka(p.tanggal),
                    style: context.teks.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) {
              if (v != null) onPilih(v);
            },
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.kecil),
            child: AspectRatio(
              aspectRatio: 1,
              child: ImageFile(path: terpilih.pathFoto ?? ''),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            terpilih.judul,
            style: context.teks.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (terpilih.tindakan.isNotEmpty)
            Text(
              'Tindakan: ${terpilih.tindakan}',
              style: context.teks.labelSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
