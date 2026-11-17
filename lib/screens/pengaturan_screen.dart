import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/database_helper.dart';
import '../data/pengaturan.dart';
import '../models/penyakit.dart';
import '../theme/app_tokens.dart';
import '../utils/format_waktu.dart';
import '../utils/riwayat_exporter.dart';
import '../widgets/komponen.dart';
import 'onboarding_screen.dart';
import 'panduan_foto_screen.dart';
import 'statistik_screen.dart';

/// Layar Pengaturan Dasar sesuai PRD F-15 dan S-18.
///
/// Dikelompokkan menjadi tiga bagian sesuai S-18:
/// 1. Aplikasi  — Mode tema, Versi aplikasi, Versi model AI, Panduan penggunaan
/// 2. Data      — Kelola penyimpanan, Ekspor Riwayat (CSV), Bagikan laporan,
///                Salin Ringkasan, Hapus Semua Riwayat / Data Lokal
/// 3. Informasi — Sumber referensi, Kebijakan privasi & data, Tentang aplikasi
class PengaturanScreen extends StatefulWidget {
  const PengaturanScreen({super.key});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  bool _sibuk = false;

  Future<void> _ubahTema(ThemeMode mode) async {
    await PengaturanStore.instance.simpanModeTema(mode);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _ekspor() async {
    setState(() => _sibuk = true);
    try {
      final data = await DatabaseHelper.instance.semuaRiwayat();
      if (data.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belum ada riwayat untuk diekspor.')),
        );
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final berkas = File(
        p.join(
          dir.path,
          'riwayat_padi_scan_'
          '${DateTime.now().toIso8601String().substring(0, 10)}.csv',
        ),
      );

      await berkas.writeAsString(RiwayatExporter.buatCsv(data));

      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(berkas.path, mimeType: 'text/csv')],
        subject: 'Riwayat Padi Scan',
        text: '${data.length} hasil identifikasi Padi Scan.',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ekspor ${data.length} hasil selesai.')),
      );
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ekspor gagal: $e')));
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  /// F-22 & F-23: Menyusun laporan ringkas riwayat & pengamatan untuk penyuluh.
  Future<void> _bagikanLaporanPenyuluh() async {
    setState(() => _sibuk = true);
    try {
      final riwayat = await DatabaseHelper.instance.semuaRiwayat();
      final lahan = await DatabaseHelper.instance.semuaPetak();
      final pengamatan = await DatabaseHelper.instance.semuaPengamatan();
      if (riwayat.isEmpty && pengamatan.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Belum ada data riwayat atau pengamatan untuk dilaporkan.'),
          ),
        );
        return;
      }

      final sb = StringBuffer()
        ..writeln('LAPORAN PEMANTAUAN KESEHATAN DAUN PADI — PADI SCAN')
        ..writeln('Tanggal laporan: ${FormatWaktu.panjang(DateTime.now())}')
        ..writeln('Jumlah lahan terdaftar: ${lahan.length}')
        ..writeln('Jumlah pemeriksaan AI: ${riwayat.length}')
        ..writeln('Jumlah catatan pengamatan manual: ${pengamatan.length}')
        ..writeln('--------------------------------------------------');

      if (riwayat.isNotEmpty) {
        sb.writeln('\nRIWAYAT IDENTIFIKASI TERBARU:');
        for (final r in riwayat.take(10)) {
          final nama = r.idPenyakit.isEmpty
              ? 'Belum meyakinkan (<70%)'
              : Penyakit.namaDariId(r.idPenyakit);
          sb.writeln(
            '- ${FormatWaktu.ringkas(r.waktu)} | $nama '
            '(${(r.keyakinan * 100).toStringAsFixed(1)}%)'
            '${r.namaPetak != null ? ' | Lahan: ${r.namaPetak}' : ''}'
            '${r.catatanPengguna.isNotEmpty ? ' | Catatan: ${r.catatanPengguna}' : ''}',
          );
        }
      }

      if (pengamatan.isNotEmpty) {
        sb.writeln('\nCATATAN PENGAMATAN LAPANGAN:');
        for (final pItem in pengamatan.take(10)) {
          sb.writeln(
            '- ${FormatWaktu.angka(pItem.tanggal)} | ${pItem.kondisiTanaman}'
            '${pItem.tindakanDilakukan.isNotEmpty ? ' | Tindakan: ${pItem.tindakanDilakukan}' : ''}',
          );
        }
      }

      sb
        ..writeln('\n--------------------------------------------------')
        ..writeln(
          'Catatan: Hasil identifikasi berasal dari model AI MobileNetV2 '
          '(TensorFlow Lite) di perangkat sebagai alat bantu keputusan awal, '
          'bukan pengganti pemeriksaan PPL/POPT.',
        );

      await Share.share(sb.toString(), subject: 'Laporan Pemantauan Padi Scan');
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membagikan laporan: $e')));
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  Future<void> _hapusSemua() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Riwayat?'),
        content: const Text(
          'Seluruh riwayat identifikasi beserta fotonya akan dihapus '
          'permanen. Tindakan ini tidak dapat dibatalkan.',
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
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
    if (konfirmasi != true) return;

    setState(() => _sibuk = true);
    try {
      final data = await DatabaseHelper.instance.semuaRiwayat();
      await DatabaseHelper.instance.hapusSemuaRiwayatDanFoto();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${data.length} riwayat dihapus.')),
      );
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  Future<void> _salinRingkasan() async {
    try {
      final data = await DatabaseHelper.instance.semuaRiwayat();
      final dikenali = data.where((r) => r.idPenyakit.isNotEmpty).length;
      final teks = StringBuffer()
        ..writeln('Ringkasan Padi Scan')
        ..writeln('Total pemeriksaan: ${data.length}')
        ..writeln('Dikenali (>=70%): $dikenali')
        ..writeln('Belum meyakinkan (<70%): ${data.length - dikenali}');
      await Clipboard.setData(ClipboardData(text: teks.toString()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ringkasan disalin ke papan klip.')),
      );
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyalin: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = PengaturanStore.instance.modeTema.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.horizontal,
          AppSpacing.md,
          AppSpacing.horizontal,
          AppSpacing.xl,
        ),
        children: [
          // Kelompok 1: Aplikasi (PRD S-18)
          KartuBagian(
            judul: 'Aplikasi',
            ikon: Icons.tune_outlined,
            anak: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Mode tampilan', style: context.teks.labelMedium),
                const SizedBox(height: AppSpacing.sm),
                for (final (nilai, label, ikon)
                    in <(ThemeMode, String, IconData)>[
                      (
                        ThemeMode.system,
                        'Ikuti sistem',
                        Icons.brightness_auto_outlined,
                      ),
                      (ThemeMode.light, 'Terang', Icons.light_mode_outlined),
                      (ThemeMode.dark, 'Gelap', Icons.dark_mode_outlined),
                    ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Semantics(
                      selected: mode == nilai,
                      button: true,
                      label: 'Mode $label',
                      child: OutlinedButton.icon(
                        onPressed: _sibuk ? null : () => _ubahTema(nilai),
                        icon: Icon(ikon),
                        label: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(mode == nilai ? '$label (aktif)' : label),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: mode == nilai
                                ? context.palet.primary
                                : context.palet.border,
                            width: mode == nilai ? 2 : 1.5,
                          ),
                          foregroundColor: mode == nilai
                              ? context.palet.primary
                              : context.palet.foreground,
                        ),
                      ),
                    ),
                  ),
                const Divider(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PanduanFotoScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Panduan Pengambilan Foto'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OnboardingScreen(
                        onSelesai: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.slideshow_outlined),
                  label: const Text('Tampilkan Pengenalan Aplikasi (Onboarding)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Kelompok 2: Data & Penyimpanan (PRD S-18)
          KartuBagian(
            judul: 'Data & Penyimpanan Lokal',
            ikon: Icons.folder_outlined,
            anak: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  button: true,
                  label: 'Ekspor riwayat ke berkas CSV',
                  child: FilledButton.icon(
                    onPressed: _sibuk ? null : _ekspor,
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Ekspor Riwayat (CSV)'),
                  ),
                ),
                const SizedBox(height: AppSpacing.smPlus),
                OutlinedButton.icon(
                  onPressed: _sibuk ? null : _bagikanLaporanPenyuluh,
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Bagikan Laporan untuk Penyuluh'),
                ),
                const SizedBox(height: AppSpacing.smPlus),
                Semantics(
                  button: true,
                  label: 'Salin ringkasan ke papan klip',
                  child: OutlinedButton.icon(
                    onPressed: _sibuk ? null : _salinRingkasan,
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('Salin Ringkasan'),
                  ),
                ),
                const SizedBox(height: AppSpacing.smPlus),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StatistikScreen()),
                  ),
                  icon: const Icon(Icons.insights_outlined),
                  label: const Text('Ringkasan Penyimpanan & Statistik'),
                ),
                const SizedBox(height: AppSpacing.smPlus),
                Semantics(
                  button: true,
                  label: 'Hapus semua riwayat',
                  child: OutlinedButton.icon(
                    onPressed: _sibuk ? null : _hapusSemua,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('Hapus Semua Riwayat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.palet.destructive,
                      side: BorderSide(color: context.palet.destructive),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Kelompok 3: Informasi, Model AI & Privasi (PRD F-15 & S-18)
          KartuBagian(
            judul: 'Provenance model',
            ikon: Icons.verified_user_outlined,
            anak: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                BarisLabelNilai(
                  label: 'Artefak',
                  nilai: 'Reimplementasi lokal',
                ),
                BarisLabelNilai(
                  label: 'Arsitektur',
                  nilai: 'MobileNetV2 (TensorFlow Lite)',
                ),
                BarisLabelNilai(label: 'Akurasi jurnal', nilai: '97,20%'),
                BarisLabelNilai(
                  label: 'Akurasi TFLite lokal',
                  nilai: '98,166%',
                ),
                Divider(height: AppSpacing.lg),
                Text(
                  'Bukan berkas bobot asli penulis. Split lokal 4.326/927/927 '
                  'berbeda dari angka jurnal 4.324/928/928 dan wajib '
                  'dilaporkan sebagai [ASUMSI] di BAB III.',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          KartuBagian(
            judul: 'Informasi, Sumber & Privasi',
            ikon: Icons.info_outline_rounded,
            anak: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BarisLabelNilai(label: 'Nama aplikasi', nilai: 'Padi Scan'),
                const BarisLabelNilai(label: 'Versi aplikasi', nilai: '2.0.0 (PRD v1.0)'),
                const BarisLabelNilai(
                  label: 'Cakupan kelas AI',
                  nilai: 'C01 Blas, C02 HDB, C03 Bercak Cokelat, C04 Sehat',
                ),
                const BarisLabelNilai(
                  label: 'Masukan model',
                  nilai: '224 x 224 piksel (RGB 0–1)',
                ),
                const BarisLabelNilai(
                  label: 'Kebijakan data',
                  nilai: '100% Offline, tanpa unggahan otomatis',
                ),
                const Divider(height: AppSpacing.lg),
                Text(
                  'Sumber referensi rekomendasi: BPTP Gorontalo (2016), '
                  'PhilRice Bacterial Leaf Blight Fact Sheet, Jackson (2025) '
                  'Pacific Pests, Pathogens, Weeds & Pesticides, Dewi dkk. '
                  '(2020) Jurnal Fitopatologi Indonesia, serta UU No. 22 '
                  'Tahun 2019.',
                  style: context.teks.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Padi Scan adalah hasil replikasi penelitian Mustofa, Arifin, dan '
            'Zulfia (2026) pada Jurnal Aplikasi Ilmu Komputer. Rekomendasi '
            'hanya memuat bahan aktif tanpa merek dagang dan dosis. Hasil '
            'aplikasi bersifat bantuan awal, bukan pengganti pemeriksaan '
            'penyuluh pertanian.',
            style: context.teks.labelSmall,
          ),
        ],
      ),
    );
  }
}
