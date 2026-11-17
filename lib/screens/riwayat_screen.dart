import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/hasil_identifikasi.dart';
import '../theme/app_tokens.dart';
import '../utils/format_waktu.dart';
import '../widgets/komponen.dart';
import 'detail_riwayat_screen.dart';

/// Halaman riwayat hasil identifikasi (F-07).
class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

enum _Urutan { terbaru, terlama, keyakinan }

class _RiwayatScreenState extends State<RiwayatScreen> {
  late Future<List<Riwayat>> _future;
  _Urutan _urutan = _Urutan.terbaru;
  String _kueri = '';
  String? _filterKelas; // null = semua kelas

  @override
  void initState() {
    super.initState();
    _future = DatabaseHelper.instance.semuaRiwayat();
    DatabaseHelper.instance.perubahanRiwayat.addListener(_muatUlang);
  }

  void _muatUlang() {
    if (!mounted) return;
    setState(() => _future = DatabaseHelper.instance.semuaRiwayat());
  }

  @override
  void dispose() {
    DatabaseHelper.instance.perubahanRiwayat.removeListener(_muatUlang);
    super.dispose();
  }

  List<Riwayat> _terapkan(List<Riwayat> data) {
    // Saring dulu, urutkan kemudian.
    final kueri = _kueri.trim().toLowerCase();
    var hasil = data.where((r) {
      if (_filterKelas != null && r.idPenyakit != _filterKelas) return false;
      if (kueri.isEmpty) return true;
      final nama = (r.penyakit?.nama ?? r.idPenyakit).toLowerCase();
      final tanggal = FormatWaktu.ringkas(r.waktu).toLowerCase();
      return nama.contains(kueri) || tanggal.contains(kueri);
    }).toList();

    switch (_urutan) {
      case _Urutan.terbaru:
        hasil.sort((a, b) => b.waktu.compareTo(a.waktu));
      case _Urutan.terlama:
        hasil.sort((a, b) => a.waktu.compareTo(b.waktu));
      case _Urutan.keyakinan:
        hasil.sort((a, b) => b.keyakinan.compareTo(a.keyakinan));
    }
    return hasil;
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
    await DatabaseHelper.instance.hapusSemuaRiwayatDanFoto();
    if (!mounted) return;
    _muatUlang();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Identifikasi'),
        actions: [
          IconButton(
            tooltip: 'Hapus semua riwayat',
            onPressed: _hapusSemua,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: FutureBuilder<List<Riwayat>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return KeadaanKosong(
              ikon: Icons.error_outline,
              judul: 'Gagal memuat riwayat',
              pesan: snapshot.error.toString(),
              aksi: OutlinedButton.icon(
                onPressed: _muatUlang,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            );
          }

          final data = snapshot.data ?? const <Riwayat>[];
          if (data.isEmpty) {
            return KeadaanKosong(
              ikon: Icons.history_rounded,
              judul: 'Belum ada riwayat',
              pesan:
                  'Hasil identifikasi yang Anda lakukan akan muncul di '
                  'sini beserta foto dan tingkat keyakinannya.',
              aksi: OutlinedButton.icon(
                onPressed: _muatUlang,
                icon: const Icon(Icons.refresh),
                label: const Text('Muat ulang'),
              ),
            );
          }

          // Daftar kelas yang benar-benar ada di riwayat, untuk pilihan filter.
          final kelasAda = <String>{for (final r in data) r.idPenyakit}.toList()
            ..sort();

          final tersusun = _terapkan(data);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm + 2,
                  AppSpacing.md,
                  0,
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _kueri = v),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Cari kelas atau tanggal',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: context.palet.muted,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sedang),
                      borderSide: BorderSide(color: context.palet.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sedang),
                      borderSide: BorderSide(color: context.palet.border),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm + 2,
                  AppSpacing.md,
                  AppSpacing.sm + 2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${tersusun.length} dari ${data.length} hasil',
                        style: context.teks.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _PemilihUrutan(
                      nilai: _urutan,
                      onUbah: (u) => setState(() => _urutan = u),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: kTargetSentuh,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  children: [
                    _ChipFilter(
                      label: 'Semua',
                      aktif: _filterKelas == null,
                      onTap: () => setState(() => _filterKelas = null),
                    ),
                    for (final k in kelasAda)
                      _ChipFilter(
                        label: k.isEmpty ? 'Tanpa hasil' : k,
                        aktif: _filterKelas == k,
                        onTap: () => setState(() => _filterKelas = k),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: tersusun.isEmpty
                    ? const KeadaanKosong(
                        ikon: Icons.search_off_rounded,
                        judul: 'Tidak ada yang cocok',
                        pesan:
                            'Ubah kata kunci pencarian atau pilih filter '
                            'kelas lain.',
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _muatUlang(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.lg,
                          ),
                          itemCount: tersusun.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm + 2),
                          itemBuilder: (context, i) {
                            final r = tersusun[i];
                            return _KartuRiwayat(
                              riwayat: r,
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DetailRiwayatScreen(riwayat: r),
                                  ),
                                );
                                if (mounted) _muatUlang();
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChipFilter extends StatelessWidget {
  const _ChipFilter({
    required this.label,
    required this.aktif,
    required this.onTap,
  });

  final String label;
  final bool aktif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Semantics(
        button: true,
        selected: aktif,
        label: 'Filter $label',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pil),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 6,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: aktif ? context.palet.primary : context.palet.muted,
              borderRadius: BorderRadius.circular(AppRadius.pil),
              border: Border.all(
                color: aktif ? context.palet.primary : context.palet.border,
              ),
            ),
            child: Text(
              label,
              style: context.teks.labelMedium?.copyWith(
                color: aktif
                    ? context.palet.onPrimary
                    : context.palet.mutedForeground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PemilihUrutan extends StatelessWidget {
  const _PemilihUrutan({required this.nilai, required this.onUbah});

  final _Urutan nilai;
  final ValueChanged<_Urutan> onUbah;

  static const _label = {
    _Urutan.terbaru: 'Terbaru',
    _Urutan.terlama: 'Terlama',
    _Urutan.keyakinan: 'Keyakinan',
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_Urutan>(
      initialValue: nilai,
      tooltip: 'Urutkan riwayat',
      onSelected: onUbah,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        for (final e in _Urutan.values)
          PopupMenuItem(
            value: e,
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    e == nilai
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: AppIkon.kecil,
                    color: context.palet.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Text(_label[e]!),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 4,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: context.palet.muted,
          borderRadius: BorderRadius.circular(AppRadius.pil),
          border: Border.all(color: context.palet.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.swap_vert_rounded,
                size: 16,
                color: context.palet.primary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _label[nilai]!,
              style: context.teks.labelMedium?.copyWith(
                color: context.palet.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuRiwayat extends StatelessWidget {
  const _KartuRiwayat({required this.riwayat, required this.onTap});

  final Riwayat riwayat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dikenali = riwayat.idPenyakit.isNotEmpty;
    final nama = dikenali
        ? (riwayat.penyakit?.nama ?? riwayat.idPenyakit)
        : 'Tidak dikenali';
    final yakin = riwayat.keyakinan * 100;
    final warna = dikenali
        ? context.warnaKeyakinan(yakin)
        : context.palet.mutedForeground;

    return Semantics(
      button: true,
      label:
          '$nama, keyakinan ${yakin.toStringAsFixed(2)} persen, '
          '${FormatWaktu.relatif(riwayat.waktu)}',
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.kecil),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: ImageFile(path: riwayat.pathFoto),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: context.teks.titleSmall?.copyWith(color: warna),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        dikenali
                            ? '${yakin.toStringAsFixed(2)}% keyakinan'
                            : 'Keyakinan ${yakin.toStringAsFixed(2)}%',
                        style: context.teks.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        FormatWaktu.relatif(riwayat.waktu),
                        style: context.teks.labelSmall,
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
          ),
        ),
      ),
    );
  }
}
