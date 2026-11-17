import 'package:flutter/material.dart';

import '../data/pengaturan.dart';
import '../models/penyakit.dart';
import '../theme/app_tokens.dart';
import '../widgets/komponen.dart';

/// Halaman Rekomendasi Penanganan & Detail Penyakit sesuai PRD F-08, F-10,
/// S-08, dan S-15.
///
/// Struktur informasi 10 butir PRD F-08:
/// 1. Nama penyakit & foto gejala asli
/// 2. Penjelasan singkat
/// 3. Gejala utama
/// 4. Penyebab & faktor pendukung
/// 5. Langkah pengamatan lanjutan
/// 6. Pencegahan
/// 7. Pengendalian kultur teknis (diprioritaskan)
/// 8. Pengendalian hayati
/// 9. Informasi pengendalian kimia (hanya bahan aktif, tanpa merek & dosis)
/// 10. Sumber referensi & tanggal peninjauan
class RekomendasiScreen extends StatelessWidget {
  const RekomendasiScreen({super.key, required this.penyakit});

  final Penyakit penyakit;

  @override
  Widget build(BuildContext context) {
    final kultur = penyakit.rekomendasiKulturTeknis;
    final hayati = penyakit.rekomendasiHayati;
    final kimia = penyakit.rekomendasiKimia;
    final adaIsi = kultur.isNotEmpty || hayati.isNotEmpty || kimia.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          penyakit.isSehat ? 'Saran Pemeliharaan' : 'Rekomendasi Penanganan',
        ),
        actions: [
          ValueListenableBuilder<Set<String>>(
            valueListenable: PengaturanStore.instance.bookmarkPenyakit,
            builder: (context, markah, _) {
              final disimpan = markah.contains(penyakit.idPenyakit);
              return IconButton(
                tooltip: disimpan ? 'Hapus dari tersimpan' : 'Simpan panduan',
                onPressed: () => PengaturanStore.instance
                    .toggleBookmarkPenyakit(penyakit.idPenyakit),
                icon: Icon(
                  disimpan ? Icons.bookmark_rounded : Icons.bookmark_border,
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
          _KepalaPenyakit(penyakit: penyakit),
          const SizedBox(height: AppSpacing.md),
          if (penyakit.isSehat)
            KartuPesan(
              warna: context.palet.success,
              ikon: Icons.verified_outlined,
              judul: 'Tidak terdeteksi gejala penyakit',
              isi:
                  'Daun terdeteksi sehat. Tetap lakukan pemantauan berkala '
                  'pada daun, batang, dan malai.',
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
            ),
          if (!penyakit.isSehat) ...[
            _PeringatanBahanAktif(),
            const SizedBox(height: AppSpacing.md),
          ],
          _AccordionBagian(
            judul: 'Langkah Pengamatan & Pencegahan',
            ikon: Icons.visibility_outlined,
            terbukaAwal: false,
            anak: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BagianTeks(
                  label: 'Langkah pengamatan lanjutan',
                  isi: penyakit.langkahPengamatan,
                ),
                const SizedBox(height: AppSpacing.smPlus),
                _BagianTeks(
                  label: 'Faktor pendukung',
                  isi: penyakit.faktorPendukung,
                ),
                const SizedBox(height: AppSpacing.smPlus),
                _BagianTeks(label: 'Pencegahan', isi: penyakit.pencegahan),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (kultur.isNotEmpty) ...[
            const KepalaBagian(
              nomor: '1',
              judul: 'Kultur Teknis dan Pencegahan',
              keterangan: 'Didahulukan sesuai pengelolaan hama terpadu.',
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            for (final r in kultur) _ButirRekomendasi(rekomendasi: r),
            const SizedBox(height: AppSpacing.md),
          ],
          if (hayati.isNotEmpty) ...[
            KepalaBagian(
              nomor: kultur.isEmpty ? '1' : '2',
              judul: 'Pengendalian Hayati',
              keterangan: penyakit.isSehat
                  ? null
                  : 'Utamakan pilihan hayati yang sesuai kondisi setempat.',
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            for (final r in hayati) _ButirRekomendasi(rekomendasi: r),
            const SizedBox(height: AppSpacing.md),
          ],
          if (kimia.isNotEmpty) ...[
            KepalaBagian(
              nomor: kultur.isEmpty && hayati.isEmpty
                  ? '1'
                  : hayati.isEmpty
                  ? '2'
                  : '3',
              judul: 'Pengendalian Kimia',
              keterangan: penyakit.isSehat
                  ? null
                  : 'Pilihan terakhir setelah kultur teknis dan hayati.',
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            for (final r in kimia) _ButirRekomendasi(rekomendasi: r),
            const SizedBox(height: AppSpacing.md),
          ],
          if (!penyakit.isSehat)
            KartuPesan(
              warna: context.palet.primary,
              ikon: Icons.support_agent_outlined,
              judul: 'Kapan meminta bantuan',
              isi:
                  'Hubungi PPL/POPT bila gejala meluas, muncul berulang, '
                  'atau keputusan pengendalian kimia perlu ditetapkan. '
                  'Bawa foto dan catatan waktu pengamatan.',
            ),
          if (!adaIsi)
            KeadaanKosong(
              ikon: Icons.inbox_outlined,
              judul: 'Belum ada rekomendasi',
              pesan:
                  'Data rekomendasi untuk kelas ini belum tersedia '
                  'di dalam basis data aplikasi.',
            ),
        ],
      ),
    );
  }
}

/// Ringkasan penyakit: foto gejala asli, kode kelas, nama, nama ilmiah,
/// penjelasan singkat, penyebab, dan gejala.
class _KepalaPenyakit extends StatelessWidget {
  const _KepalaPenyakit({required this.penyakit});

  final Penyakit penyakit;

  @override
  Widget build(BuildContext context) {
    final warna = penyakit.isSehat
        ? context.palet.success
        : context.palet.destructive;

    return Card(
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
                    size: 48,
                    color: context.palet.primary,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.horizontal),
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
                          if (penyakit.kodeKelas != '-')
                            Text(
                              'Kelas ${penyakit.kodeKelas}',
                              style: context.teks.labelSmall?.copyWith(
                                color: context.palet.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          Text(
                            penyakit.nama,
                            style: context.teks.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Lencana(
                      teks: penyakit.isSehat ? 'Sehat' : 'Bergejala',
                      warna: warna,
                      ikon: penyakit.isSehat
                          ? Icons.eco_outlined
                          : Icons.coronavirus_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  penyakit.namaLatin,
                  style: context.teks.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: AppSpacing.smPlus),
                Text(
                  penyakit.penjelasanSingkat,
                  style: context.teks.bodyMedium,
                ),
                const Divider(height: AppSpacing.lg),
                _BagianTeks(label: 'Penyebab', isi: penyakit.penyebab),
                const SizedBox(height: AppSpacing.smPlus),
                _BagianTeks(label: 'Gejala utama', isi: penyakit.gejala),
                const SizedBox(height: AppSpacing.smPlus),
                Text(
                  'Ditinjau pada: ${penyakit.tanggalPeninjauan} · '
                  'Sumber: BPTP, PhilRice, Pacific Pests (Jackson, 2025)',
                  style: context.teks.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccordionBagian extends StatelessWidget {
  const _AccordionBagian({
    required this.judul,
    required this.ikon,
    required this.anak,
    this.terbukaAwal = false,
  });

  final String judul;
  final IconData ikon;
  final Widget anak;
  final bool terbukaAwal;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: terbukaAwal,
      leading: Icon(ikon, size: AppIkon.sedang),
      title: Text(judul, style: context.teks.titleMedium),
      childrenPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      children: [anak],
    );
  }
}

class _BagianTeks extends StatelessWidget {
  const _BagianTeks({required this.label, required this.isi});

  final String label;
  final String isi;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: context.teks.labelSmall?.copyWith(
            color: context.palet.primary,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(isi, style: context.teks.bodyMedium),
      ],
    );
  }
}

class _PeringatanBahanAktif extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return KartuPesan(
      warna: context.palet.warning,
      ikon: Icons.info_outline,
      judul: 'Tentang bahan aktif',
      isi:
          'Rekomendasi pengendalian kimia hanya mencantumkan bahan aktif '
          'tanpa merek dagang dan tanpa dosis otomatis. Ikuti petunjuk pada '
          'label kemasan serta ketentuan Undang-Undang Nomor 22 Tahun 2019 '
          'tentang Sistem Budi Daya Pertanian Berkelanjutan. Sesuaikan '
          'tindakan dengan kondisi lapangan bersama penyuluh pertanian.',
    );
  }
}

class _ButirRekomendasi extends StatelessWidget {
  const _ButirRekomendasi({required this.rekomendasi});

  final Rekomendasi rekomendasi;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: ExcludeSemantics(
                    child: Icon(
                      Icons.check_circle_outline,
                      size: AppIkon.kecil,
                      color: context.palet.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: Text(
                    rekomendasi.isi,
                    style: context.teks.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      Icons.menu_book_outlined,
                      size: 13,
                      color: context.palet.mutedForeground,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Sumber: ${rekomendasi.sumber} · '
                      'Ditinjau ${rekomendasi.ditinjauPada}',
                      style: context.teks.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
