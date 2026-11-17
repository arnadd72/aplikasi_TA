import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../data/pengaturan.dart';
import '../models/penyakit.dart';
import '../theme/app_tokens.dart';
import '../widgets/komponen.dart';
import 'detail_penyakit_screen.dart';
import 'panduan_foto_screen.dart';

/// Halaman Pustaka Penyakit & Edukasi (PRD F-10, F-21, F-24, F-25, S-14, S-15).
///
/// Menampilkan:
/// - Pencarian penyakit (F-21) dan filter markah / bookmark (F-25)
/// - Empat kelas penyakit (`C01..C04`) dengan foto gejala asli (`assets/images/*.jpg`),
///   nama ilmiah, gejala utama, dan tombol simpan markah
/// - Artikel edukasi budidaya, pencegahan, dan panduan pengambilan foto (F-24)
class InformasiScreen extends StatefulWidget {
  const InformasiScreen({super.key});

  @override
  State<InformasiScreen> createState() => _InformasiScreenState();
}

class _InformasiScreenState extends State<InformasiScreen> {
  late Future<List<Penyakit>> _future;
  String _kueri = '';
  bool _hanyaTersimpan = false;

  @override
  void initState() {
    super.initState();
    _future = DatabaseHelper.instance.semuaPenyakit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informasi Penyakit'),
        actions: [
          IconButton(
            tooltip: 'Panduan ambil foto',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PanduanFotoScreen()),
            ),
            icon: const Icon(Icons.photo_camera_outlined),
          ),
        ],
      ),
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

          return ValueListenableBuilder<Set<String>>(
            valueListenable: PengaturanStore.instance.bookmarkPenyakit,
            builder: (context, markah, _) {
              final kueri = _kueri.trim().toLowerCase();
              final tersaring = data.where((p) {
                if (_hanyaTersimpan && !markah.contains(p.idPenyakit)) {
                  return false;
                }
                if (kueri.isEmpty) return true;
                return p.nama.toLowerCase().contains(kueri) ||
                    p.namaLatin.toLowerCase().contains(kueri) ||
                    p.gejala.toLowerCase().contains(kueri) ||
                    p.kodeKelas.toLowerCase().contains(kueri);
              }).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.horizontal,
                  AppSpacing.sm,
                  AppSpacing.horizontal,
                  AppSpacing.xl,
                ),
                children: [
                  Text(
                    'Panduan Penyakit & Pustaka',
                    style: context.teks.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Empat kelas keluaran model MobileNetV2 beserta gejala, '
                    'faktor pendukung, pencegahan, dan pengendalian.',
                    style: context.teks.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    onChanged: (v) => setState(() => _kueri = v),
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: 'Cari penyakit, patogen, atau ciri gejala',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.smPlus),
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('Semua Kelas (4)'),
                        selected: !_hanyaTersimpan,
                        onSelected: (_) =>
                            setState(() => _hanyaTersimpan = false),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FilterChip(
                        label: Text('Tersimpan (${markah.length})'),
                        selected: _hanyaTersimpan,
                        onSelected: (_) =>
                            setState(() => _hanyaTersimpan = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (tersaring.isEmpty)
                    const KeadaanKosong(
                      ikon: Icons.bookmark_border_rounded,
                      judul: 'Tidak ada panduan yang cocok',
                      pesan:
                          'Ubah kata kunci pencarian atau simpan panduan '
                          'dengan menekan ikon markah pada kartu penyakit.',
                    )
                  else
                    for (final p in tersaring)
                      _KartuPenyakit(
                        penyakit: p,
                        disimpan: markah.contains(p.idPenyakit),
                        onToggleSimpan: () => PengaturanStore.instance
                            .toggleBookmarkPenyakit(p.idPenyakit),
                      ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Artikel Edukasi Budidaya', style: context.teks.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Panduan praktis pemeliharaan tanaman padi yang tersedia '
                    'secara luring.',
                    style: context.teks.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.smPlus),
                  const _DaftarArtikelEdukasi(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _KartuPenyakit extends StatelessWidget {
  const _KartuPenyakit({
    required this.penyakit,
    required this.disimpan,
    required this.onToggleSimpan,
  });

  final Penyakit penyakit;
  final bool disimpan;
  final VoidCallback onToggleSimpan;

  @override
  Widget build(BuildContext context) {
    final warna = penyakit.isSehat
        ? context.palet.success
        : context.palet.destructive;

    return Semantics(
      button: true,
      label:
          '${penyakit.nama}, ${penyakit.namaLatin}. '
          'Ketuk untuk membaca detail penyakit dan rekomendasi penanganan.',
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DetailPenyakitScreen(penyakit: penyakit),
            ),
          ),
          borderRadius: BorderRadius.circular(AppRadius.sedang),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  penyakit.pathGambar,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => ColoredBox(
                    color: context.palet.muted,
                    child: Center(
                      child: Icon(
                        Icons.eco_outlined,
                        size: 40,
                        color: context.palet.primary,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${penyakit.kodeKelas} · ${penyakit.nama}',
                                style: context.teks.titleMedium,
                              ),
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
                        Lencana(
                          teks: penyakit.isSehat ? 'Sehat' : 'Penyakit',
                          warna: warna,
                          ikon: penyakit.isSehat
                              ? Icons.eco_outlined
                              : Icons.coronavirus_outlined,
                        ),
                        IconButton(
                          tooltip: disimpan
                              ? 'Hapus dari tersimpan'
                              : 'Simpan panduan',
                          onPressed: onToggleSimpan,
                          icon: Icon(
                            disimpan
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: context.palet.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      penyakit.gejala,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: context.teks.bodySmall?.copyWith(
                        color: context.palet.cardForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaftarArtikelEdukasi extends StatelessWidget {
  const _DaftarArtikelEdukasi();

  static const _artikel = <(String, String, String)>[
    (
      'Prinsip Pengelolaan Hama Terpadu (PHT)',
      'Pencegahan dan kultur teknis menjadi fondasi utama kesehatan tanaman.',
      'Pengelolaan Hama Terpadu (PHT) mendahulukan penggunaan varietas tahan, '
          'sanitasi lahan dan jerami, pengaturan jarak tanam (seperti jajar '
          'legowo), serta pengamatan rutin setiap minggu. Pengendalian kimia '
          'hanya digunakan sebagai langkah terakhir dengan bahan aktif yang '
          'terdaftar resmi dan sesuai anjuran penyuluh (PPL/POPT).',
    ),
    (
      'Pemupukan Berimbang & Pengairan Berselang',
      'Kelebihan nitrogen dan genangan terus-menerus memicu Blas dan HDB.',
      'Pemberian pupuk nitrogen (urea) yang berlebihan membuat jaringan daun '
          'lebih lunak dan rentan terhadap jamur Pyricularia oryzae (Blas) '
          'maupun bakteri Xanthomonas oryzae (HDB). Imbangi dengan unsur '
          'kalium (K) serta terapkan pengairan berselang (intermittent '
          'irrigation) untuk menjaga kelembapan tajuk tanaman tetap sehat.',
    ),
    (
      'Kapan Harus Menghubungi Penyuluh / POPT',
      'Kenali batas kemampuan diagnosis AI berbasis foto daun tunggal.',
      'Model MobileNetV2 di aplikasi ini hanya mengklasifikasi empat kelas '
          'kondisi daun (Blas, HDB, Bercak Cokelat, dan Daun Sehat). Gejala '
          'akibat hama penggerek batang, wereng, virus tungro, atau kahat '
          'unsur hara mikro memerlukan pemeriksaan langsung di lapangan oleh '
          'PPL atau POPT setempat.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (judul, ringkas, isi) in _artikel)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ExpansionTile(
              leading: Icon(
                Icons.article_outlined,
                color: context.palet.primary,
              ),
              title: Text(judul, style: context.teks.titleSmall),
              subtitle: Text(ringkas, style: context.teks.labelMedium),
              childrenPadding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              children: [
                Text(isi, style: context.teks.bodySmall),
              ],
            ),
          ),
      ],
    );
  }
}
