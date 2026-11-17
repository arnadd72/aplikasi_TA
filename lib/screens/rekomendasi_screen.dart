import 'package:flutter/material.dart';

import '../models/penyakit.dart';
import '../theme/app_tokens.dart';
import '../widgets/komponen.dart';

/// Halaman rekomendasi penanganan (F-05).
///
/// Urutan mengikuti pengelolaan hama terpadu: kultur teknis dan pencegahan
/// didahulukan sebelum pengendalian hayati dan kimia (subbab 2.2.2).
/// Hanya bahan aktif tanpa merek dagang dan dosis (NF-05).
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
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
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

/// Ringkasan penyakit: nama, nama latin, penyebab, gejala.
class _KepalaPenyakit extends StatelessWidget {
  const _KepalaPenyakit({required this.penyakit});

  final Penyakit penyakit;

  @override
  Widget build(BuildContext context) {
    final warna = penyakit.isSehat
        ? context.palet.success
        : context.palet.destructive;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(penyakit.nama, style: context.teks.headlineSmall),
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
            const SizedBox(height: AppSpacing.md),
            _BagianTeks(label: 'Penyebab', isi: penyakit.penyebab),
            const SizedBox(height: AppSpacing.sm + 4),
            _BagianTeks(label: 'Gejala', isi: penyakit.gejala),
          ],
        ),
      ),
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
            letterSpacing: 0.8,
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
          'tanpa merek dagang dan tanpa dosis. Ikuti petunjuk pada label '
          'kemasan serta ketentuan Undang-Undang Nomor 22 Tahun 2019 tentang '
          'Sistem Budi Daya Pertanian Berkelanjutan. Untuk pemilihan produk '
          'dan takaran, konsultasikan dengan penyuluh pertanian setempat.',
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
                      'Sumber: ${rekomendasi.sumber}',
                      style: context.teks.labelSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
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
