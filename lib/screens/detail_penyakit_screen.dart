import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../data/pengaturan.dart';
import '../models/penyakit.dart';
import '../theme/app_tokens.dart';
import '../widgets/komponen.dart';
import 'rekomendasi_screen.dart';

/// Layar Detail Penyakit sesuai PRD F-10 dan S-15.
///
/// Menampilkan:
/// - Foto gejala asli tanaman padi (`assets/images/*.jpg`)
/// - Nama penyakit, Kode kelas (`C01..C04`), dan Nama ilmiah patogen
/// - Ciri visual & Gejala
/// - Faktor pendukung lingkungan
/// - Langkah pengamatan lanjutan
/// - Pencegahan
/// - Pengendalian & tombol menuju Rekomendasi Penanganan Lengkap (S-08)
/// - Daftar referensi literatur pertanian
class DetailPenyakitScreen extends StatefulWidget {
  const DetailPenyakitScreen({super.key, required this.penyakit});

  final Penyakit penyakit;

  @override
  State<DetailPenyakitScreen> createState() => _DetailPenyakitScreenState();
}

class _DetailPenyakitScreenState extends State<DetailPenyakitScreen> {
  late Penyakit _penyakit;

  @override
  void initState() {
    super.initState();
    _penyakit = widget.penyakit;
    _muatLengkap();
  }

  Future<void> _muatLengkap() async {
    try {
      final lengkap = await DatabaseHelper.instance.penyakitById(
        _penyakit.idPenyakit,
      );
      if (lengkap != null && mounted) {
        setState(() => _penyakit = lengkap);
      }
    } on Object catch (e) {
      debugPrint('[DetailPenyakit] gagal memuat rekomendasi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _penyakit;
    final warna = p.isSehat
        ? context.palet.success
        : context.palet.destructive;
    final sumberUnik = <String>{
      for (final r in p.rekomendasi)
        if (r.sumber.trim().isNotEmpty && r.sumber.trim() != '-')
          r.sumber.trim(),
    }.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Penyakit'),
        actions: [
          ValueListenableBuilder<Set<String>>(
            valueListenable: PengaturanStore.instance.bookmarkPenyakit,
            builder: (context, markah, _) {
              final disimpan = markah.contains(p.idPenyakit);
              return IconButton(
                tooltip: disimpan
                    ? 'Hapus dari panduan tersimpan'
                    : 'Simpan panduan penyakit',
                onPressed: () => PengaturanStore.instance
                    .toggleBookmarkPenyakit(p.idPenyakit),
                icon: Icon(
                  disimpan
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.horizontal,
          AppSpacing.md,
          AppSpacing.horizontal,
          AppSpacing.xl,
        ),
        children: [
          // 1. Foto gejala asli
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sedang),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                p.pathGambar,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: context.palet.muted,
                  child: Center(
                    child: Icon(
                      Icons.eco_outlined,
                      size: 48,
                      color: context.palet.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. Nama penyakit & Nama ilmiah patogen
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      Lencana(
                        teks: 'Kelas ${p.kodeKelas}',
                        warna: context.palet.primary,
                        ikon: Icons.label_outline,
                      ),
                      Lencana(
                        teks: p.isSehat ? 'Kondisi Sehat' : 'Penyakit Daun',
                        warna: warna,
                        ikon: p.isSehat
                            ? Icons.eco_outlined
                            : Icons.coronavirus_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.smPlus),
                  Text(p.nama, style: context.teks.headlineMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    p.namaLatin,
                    style: context.teks.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: context.palet.mutedForeground,
                    ),
                  ),
                  const Divider(height: AppSpacing.lg),
                  BarisLabelNilai(
                    label: 'Penyebab / Patogen',
                    nilai: p.penyebab,
                  ),
                  BarisLabelNilai(
                    label: 'Ditinjau pada',
                    nilai: p.tanggalPeninjauan,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 3. Ciri visual & Gejala
          KartuBagian(
            judul: 'Gejala & Ciri Visual',
            ikon: Icons.visibility_outlined,
            anak: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.gejala, style: context.teks.bodyMedium),
                if (p.daftarGejala.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.smPlus),
                  for (final butir in p.daftarGejala)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: context.palet.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(butir, style: context.teks.bodySmall),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 4. Faktor pendukung
          KartuBagian(
            judul: 'Faktor Pendukung',
            ikon: Icons.wb_cloudy_outlined,
            anak: Text(p.faktorPendukung, style: context.teks.bodyMedium),
          ),
          const SizedBox(height: AppSpacing.md),

          // 5. Pencegahan
          KartuBagian(
            judul: 'Pencegahan',
            ikon: Icons.shield_outlined,
            anak: Text(p.pencegahan, style: context.teks.bodyMedium),
          ),
          const SizedBox(height: AppSpacing.md),

          // 6. Pengendalian & Tombol Rekomendasi Penanganan Lengkap (S-08)
          KartuBagian(
            judul: 'Pengendalian & Penanganan',
            ikon: Icons.medical_information_outlined,
            anak: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  p.langkahPengamatan,
                  style: context.teks.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RekomendasiScreen(penyakit: p),
                    ),
                  ),
                  icon: const Icon(Icons.assignment_turned_in_outlined),
                  label: Text(
                    p.isSehat
                        ? 'Lihat Saran Pemeliharaan'
                        : 'Lihat Rekomendasi Penanganan Lengkap',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 7. Daftar referensi
          KartuBagian(
            judul: 'Daftar Referensi',
            ikon: Icons.menu_book_outlined,
            anak: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (sumberUnik.isEmpty)
                  Text(
                    'BPTP Gorontalo (2016), PhilRice Fact Sheet, Jackson (2025), '
                    'Dewi dkk. (2020), dan UU No. 22 Tahun 2019.',
                    style: context.teks.bodySmall,
                  )
                else
                  for (final s in sumberUnik)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: context.teks.bodySmall),
                          Expanded(
                            child: Text(s, style: context.teks.bodySmall),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
