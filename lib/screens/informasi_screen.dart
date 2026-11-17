import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/penyakit.dart';
import '../theme/app_tokens.dart';
import '../widgets/komponen.dart';
import 'rekomendasi_screen.dart';

/// Halaman informasi setiap penyakit (F-08).
class InformasiScreen extends StatefulWidget {
  const InformasiScreen({super.key});

  @override
  State<InformasiScreen> createState() => _InformasiScreenState();
}

class _InformasiScreenState extends State<InformasiScreen> {
  late Future<List<Penyakit>> _future;

  @override
  void initState() {
    super.initState();
    _future = DatabaseHelper.instance.semuaPenyakit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informasi Penyakit')),
      body: FutureBuilder<List<Penyakit>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return KeadaanKosong(
              ikon: Icons.error_outline,
              judul: 'Gagal memuat data',
              pesan: snapshot.error.toString(),
            );
          }

          final data = snapshot.data ?? const <Penyakit>[];
          if (data.isEmpty) {
            return const KeadaanKosong(
              ikon: Icons.inbox_outlined,
              judul: 'Data belum tersedia',
              pesan:
                  'Basis data penyakit belum terisi. Jalankan ulang '
                  'aplikasi agar data contoh dimuat.',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              Text(
                'Empat kelas yang dikenali',
                style: context.teks.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Kelas keluaran model MobileNetV2 yang dimanfaatkan dalam '
                'penelitian ini. Ketuk satu kartu untuk membaca penyebab, '
                'gejala, dan rekomendasi penanganannya.',
                style: context.teks.bodyMedium?.copyWith(
                  color: context.palet.mutedForeground,
                ),
              ),
              const SizedBox(height: AppSpacing.md + 2),
              for (final p in data) _KartuPenyakit(penyakit: p),
            ],
          );
        },
      ),
    );
  }
}

class _KartuPenyakit extends StatelessWidget {
  const _KartuPenyakit({required this.penyakit});

  final Penyakit penyakit;

  @override
  Widget build(BuildContext context) {
    final warna = penyakit.isSehat
        ? context.palet.success
        : context.palet.destructive;

    return Semantics(
      button: true,
      label:
          '${penyakit.nama}, ${penyakit.namaLatin}. '
          'Ketuk untuk membaca rekomendasi penanganan.',
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RekomendasiScreen(penyakit: penyakit),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: warna.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.kecil),
                        ),
                        child: Icon(
                          penyakit.isSehat
                              ? Icons.eco_outlined
                              : Icons.coronavirus_outlined,
                          color: warna,
                          size: AppIkon.sedang,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(penyakit.nama, style: context.teks.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            penyakit.namaLatin,
                            style: context.teks.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ExcludeSemantics(
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: context.palet.mutedForeground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm + 4),
                Text(
                  penyakit.gejala,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.teks.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
