import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/hasil_identifikasi.dart';
import '../models/penyakit.dart';
import '../theme/app_tokens.dart';
import '../utils/format_waktu.dart';
import '../widgets/komponen.dart';

/// Ringkasan hasil identifikasi tersimpan (pendukung F-07).
///
/// Menampilkan jumlah pemeriksaan, sebaran kelas, dan tingkat keyakinan
/// rata-rata, dihitung langsung dari tabel `riwayat` di basis data lokal.
class StatistikScreen extends StatefulWidget {
  const StatistikScreen({super.key});

  @override
  State<StatistikScreen> createState() => _StatistikScreenState();
}

class _StatistikScreenState extends State<StatistikScreen> {
  late Future<List<Riwayat>> _future;

  @override
  void initState() {
    super.initState();
    _future = DatabaseHelper.instance.semuaRiwayat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      body: FutureBuilder<List<Riwayat>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return KeadaanKosong(
              ikon: Icons.error_outline,
              judul: 'Gagal memuat statistik',
              pesan: snapshot.error.toString(),
            );
          }

          final data = snapshot.data ?? const <Riwayat>[];
          if (data.isEmpty) {
            return const KeadaanKosong(
              ikon: Icons.insights_rounded,
              judul: 'Belum ada data',
              pesan:
                  'Statistik tersusun setelah Anda menyelesaikan '
                  'identifikasi pertama.',
            );
          }

          return _Isi(data: data);
        },
      ),
    );
  }
}

class _Isi extends StatelessWidget {
  const _Isi({required this.data});

  final List<Riwayat> data;

  @override
  Widget build(BuildContext context) {
    final total = data.length;
    final dikenali = data.where((r) => r.idPenyakit.isNotEmpty).length;
    final tanpaHasil = total - dikenali;

    final keyakinan = data.map((r) => r.keyakinan * 100).toList();
    final rataRata = keyakinan.reduce((a, b) => a + b) / keyakinan.length;
    final tertinggi = keyakinan.reduce((a, b) => a > b ? a : b);
    final terendah = keyakinan.reduce((a, b) => a < b ? a : b);

    // Sebaran per kelas, hanya untuk hasil yang dikenali.
    final sebaran = <String, int>{};
    for (final r in data) {
      if (r.idPenyakit.isEmpty) continue;
      sebaran[r.idPenyakit] = (sebaran[r.idPenyakit] ?? 0) + 1;
    }
    final urut = sebaran.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final terbanyak = urut.isEmpty ? 1 : urut.first.value;

    final terakhir = data
        .map((r) => r.waktu)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        Text('Ringkasan pemeriksaan', style: context.teks.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Dihitung dari $total hasil yang tersimpan di perangkat ini.',
          style: context.teks.bodyMedium?.copyWith(
            color: context.palet.mutedForeground,
          ),
        ),
        const SizedBox(height: AppSpacing.md + 2),
        // `IntrinsicHeight` wajib: di dalam `ListView` tinggi anak tidak
        // terbatas sehingga `CrossAxisAlignment.stretch` akan meminta tinggi
        // tak hingga dan tata letak gagal.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _KotakAngka(
                  judul: 'Total',
                  nilai: '$total',
                  satuan: 'pemeriksaan',
                  warna: context.palet.primary,
                  ikon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: _KotakAngka(
                  judul: 'Dikenali',
                  nilai: '$dikenali',
                  satuan: 'di atas 70%',
                  warna: context.palet.success,
                  ikon: Icons.check_circle_outline,
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
                child: _KotakAngka(
                  judul: 'Tanpa hasil',
                  nilai: '$tanpaHasil',
                  satuan: 'di bawah 70%',
                  warna: context.palet.warning,
                  ikon: Icons.help_outline,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: _KotakAngka(
                  judul: 'Rata-rata',
                  nilai: rataRata.toStringAsFixed(1),
                  satuan: 'persen keyakinan',
                  warna: context.palet.accent,
                  ikon: Icons.percent_rounded,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        KartuBagian(
          judul: 'Sebaran kelas',
          ikon: Icons.bar_chart_rounded,
          anak: urut.isEmpty
              ? Text(
                  'Belum ada hasil yang melewati ambang batas 70%.',
                  style: context.teks.bodySmall,
                )
              : Column(
                  children: [
                    for (final e in urut)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.sm + 2,
                        ),
                        child: Semantics(
                          label: '${Penyakit.namaDariId(e.key)}, ${e.value} hasil',
                          child: ExcludeSemantics(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        Penyakit.namaDariId(e.key),
                                        style: context.teks.bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      '${e.value}',
                                      style: context.teks.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: context.palet.foreground,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pil,
                                  ),
                                  child: LinearProgressIndicator(
                                    value: e.value / terbanyak,
                                    minHeight: 6,
                                    color: context.palet.primary,
                                    backgroundColor: context.palet.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        KartuBagian(
          judul: 'Tingkat keyakinan',
          ikon: Icons.speed_rounded,
          anak: Column(
            children: [
              BarisLabelNilai(
                label: 'Tertinggi',
                nilai: '${tertinggi.toStringAsFixed(2)}%',
              ),
              BarisLabelNilai(
                label: 'Terendah',
                nilai: '${terendah.toStringAsFixed(2)}%',
              ),
              BarisLabelNilai(
                label: 'Rata-rata',
                nilai: '${rataRata.toStringAsFixed(2)}%',
              ),
              BarisLabelNilai(
                label: 'Pemeriksaan terakhir',
                nilai: FormatWaktu.relatif(terakhir),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Ambang batas keputusan mengikuti aturan R5: hasil di bawah 70% '
          'tidak diberi diagnosis. Statistik ini bukan penilaian akurasi '
          'model; akurasi diukur pada data uji penelitian.',
          style: context.teks.labelSmall,
        ),
      ],
    );
  }
}

class _KotakAngka extends StatelessWidget {
  const _KotakAngka({
    required this.judul,
    required this.nilai,
    required this.satuan,
    required this.warna,
    required this.ikon,
  });

  final String judul;
  final String nilai;
  final String satuan;
  final Color warna;
  final IconData ikon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$judul: $nilai $satuan',
      child: ExcludeSemantics(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(ikon, size: AppIkon.kecil, color: warna),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        judul,
                        style: context.teks.labelMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  nilai,
                  style: context.teks.headlineMedium?.copyWith(color: warna),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  satuan,
                  style: context.teks.labelSmall,
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
