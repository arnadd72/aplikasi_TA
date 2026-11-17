import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/database_helper.dart';
import '../data/pengaturan.dart';
import '../theme/app_tokens.dart';
import '../utils/riwayat_exporter.dart';
import '../widgets/komponen.dart';

/// Layar pengaturan aplikasi.
///
/// Berisi pilihan tema, ekspor riwayat, dan pembersihan data. Seluruh
/// tindakan berjalan di perangkat, tanpa jaringan (NF-01).
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
      // API `share_plus` 10.x: `Share.shareXFiles`.
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
        ..writeln('Tanpa hasil: ${data.length - dikenali}');
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
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          KartuBagian(
            judul: 'Tampilan',
            ikon: Icons.palette_outlined,
            anak: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mode tema', style: context.teks.labelMedium),
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
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
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
            judul: 'Data',
            ikon: Icons.folder_outlined,
            anak: Column(
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
                const SizedBox(height: AppSpacing.sm + 2),
                Semantics(
                  button: true,
                  label: 'Salin ringkasan ke papan klip',
                  child: OutlinedButton.icon(
                    onPressed: _sibuk ? null : _salinRingkasan,
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('Salin Ringkasan'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm + 2),
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
          KartuBagian(
            judul: 'Tentang aplikasi',
            ikon: Icons.info_outline_rounded,
            anak: Column(
              children: const [
                BarisLabelNilai(label: 'Nama', nilai: 'Padi Scan'),
                BarisLabelNilai(label: 'Versi', nilai: '2.0.0'),
                BarisLabelNilai(
                  label: 'Model',
                  nilai: 'MobileNetV2, TFLite (replikasi lokal)',
                ),
                BarisLabelNilai(
                  label: 'Masukan model',
                  nilai: '224 x 224 piksel',
                ),
                BarisLabelNilai(label: 'Jaringan', nilai: 'Tidak diperlukan'),
                Divider(height: AppSpacing.lg),
              ],
            ),
          ),
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
