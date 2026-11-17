import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/catatan_lapangan.dart';
import '../models/hasil_identifikasi.dart';
import '../models/penyakit.dart';
import '../theme/app_tokens.dart';
import '../utils/format_waktu.dart';
import '../widgets/komponen.dart';
import 'detail_riwayat_screen.dart';
import 'kamera_identifikasi_screen.dart';

/// Halaman Riwayat Identifikasi sesuai PRD F-09, F-20, dan S-09.
///
/// Fitur:
/// - Pencarian teks (nama penyakit, lahan, catatan, tanggal)
/// - Filter berdasarkan penyakit
/// - Filter berdasarkan lahan (`idPetak`)
/// - Kartu riwayat menampilkan thumbnail foto, nama hasil, tanggal,
///   nama lahan (jika tersedia), dan status penanganan
/// - Empty state "Belum ada hasil pemeriksaan." + tombol "Identifikasi Penyakit"
class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key, this.onMulaiIdentifikasi});

  final VoidCallback? onMulaiIdentifikasi;

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

enum _Urutan { terbaru, terlama, keyakinan }

enum _RentangTanggal { semua, tujuhHari, tigaPuluhHari }

class _DataRiwayatLengkap {
  final List<Riwayat> riwayat;
  final List<Petak> lahan;

  const _DataRiwayatLengkap({required this.riwayat, required this.lahan});
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  late Future<_DataRiwayatLengkap> _future;
  _Urutan _urutan = _Urutan.terbaru;
  _RentangTanggal _rentangTanggal = _RentangTanggal.semua;
  String _kueri = '';
  String? _filterKelas;
  int? _filterLahan;

  @override
  void initState() {
    super.initState();
    _future = _ambilData();
    DatabaseHelper.instance.perubahanRiwayat.addListener(_muatUlang);
  }

  Future<_DataRiwayatLengkap> _ambilData() async {
    final riwayat = await DatabaseHelper.instance.semuaRiwayat();
    List<Petak> lahan = const [];
    try {
      lahan = await DatabaseHelper.instance.semuaPetak();
    } on Object catch (e) {
      debugPrint('[Riwayat] gagal memuat lahan: $e');
    }
    return _DataRiwayatLengkap(riwayat: riwayat, lahan: lahan);
  }

  void _muatUlang() {
    if (!mounted) return;
    setState(() => _future = _ambilData());
  }

  @override
  void dispose() {
    DatabaseHelper.instance.perubahanRiwayat.removeListener(_muatUlang);
    super.dispose();
  }

  List<Riwayat> _terapkan(List<Riwayat> data) {
    final kueri = _kueri.trim().toLowerCase();
    final sekarang = DateTime.now();
    var hasil = data.where((r) {
      if (_filterKelas != null && r.idPenyakit != _filterKelas) return false;
      if (_filterLahan != null && r.idPetak != _filterLahan) return false;
      if (_rentangTanggal == _RentangTanggal.tujuhHari &&
          sekarang.difference(r.waktu).inDays > 7) {
        return false;
      }
      if (_rentangTanggal == _RentangTanggal.tigaPuluhHari &&
          sekarang.difference(r.waktu).inDays > 30) {
        return false;
      }
      if (kueri.isEmpty) return true;
      final nama =
          (r.penyakit?.nama ?? Penyakit.namaDariId(r.idPenyakit)).toLowerCase();
      final kode = r.idPenyakit.toLowerCase();
      final lahan = (r.namaPetak ?? '').toLowerCase();
      final catatan = r.catatanPengguna.toLowerCase();
      final tanggal = FormatWaktu.ringkas(r.waktu).toLowerCase();
      return nama.contains(kueri) ||
          kode.contains(kueri) ||
          lahan.contains(kueri) ||
          catatan.contains(kueri) ||
          tanggal.contains(kueri);
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (widget.onMulaiIdentifikasi != null) {
            widget.onMulaiIdentifikasi!();
          } else {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const KameraIdentifikasiScreen(),
              ),
            );
            if (mounted) _muatUlang();
          }
        },
        icon: const Icon(Icons.photo_camera_outlined),
        label: const Text('Identifikasi'),
      ),
      body: FutureBuilder<_DataRiwayatLengkap>(
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

          final paket =
              snapshot.data ??
              const _DataRiwayatLengkap(riwayat: [], lahan: []);
          final data = paket.riwayat;
          final daftarLahan = paket.lahan;

          if (data.isEmpty) {
            return KeadaanKosong(
              ikon: Icons.history_rounded,
              judul: 'Belum ada hasil pemeriksaan.',
              pesan:
                  'Hasil identifikasi daun padi yang Anda lakukan akan '
                  'tersimpan di sini beserta foto, skor, dan nama lahan.',
              aksi: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onMulaiIdentifikasi != null) ...[
                    FilledButton.icon(
                      onPressed: widget.onMulaiIdentifikasi,
                      icon: const Icon(Icons.center_focus_strong_outlined),
                      label: const Text('Identifikasi Penyakit'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  OutlinedButton.icon(
                    onPressed: _muatUlang,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Muat ulang'),
                  ),
                ],
              ),
            );
          }

          final kelasAda = <String>{for (final r in data) r.idPenyakit}.toList()
            ..sort();
          final tersusun = _terapkan(data);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.horizontal,
                  AppSpacing.sm,
                  AppSpacing.horizontal,
                  0,
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _kueri = v),
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Cari penyakit, lahan, catatan, atau tanggal',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.horizontal,
                  AppSpacing.sm,
                  AppSpacing.horizontal,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${tersusun.length} dari ${data.length} pemeriksaan',
                        style: context.teks.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (daftarLahan.isNotEmpty) ...[
                      PopupMenuButton<int?>(
                        tooltip: 'Filter berdasarkan lahan',
                        onSelected: (v) =>
                            setState(() => _filterLahan = v == -1 ? null : v),
                        itemBuilder: (context) => [
                          const PopupMenuItem<int?>(
                            value: -1,
                            child: Text('Semua Lahan'),
                          ),
                          for (final l in daftarLahan)
                            PopupMenuItem<int?>(
                              value: l.idPetak,
                              child: Text(l.nama),
                            ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm + 4,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: _filterLahan != null
                                ? context.palet.accent
                                : context.palet.card,
                            borderRadius: BorderRadius.circular(
                              AppRadius.kecil,
                            ),
                            border: Border.all(color: context.palet.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.grass_outlined,
                                size: 16,
                                color: context.palet.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _filterLahan == null
                                    ? 'Semua Lahan'
                                    : (daftarLahan
                                              .where(
                                                (l) =>
                                                    l.idPetak == _filterLahan,
                                              )
                                              .firstOrNull
                                              ?.nama ??
                                          'Lahan'),
                                style: context.teks.labelMedium?.copyWith(
                                  color: context.palet.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    _PemilihTanggal(
                      nilai: _rentangTanggal,
                      onUbah: (v) => setState(() => _rentangTanggal = v),
                    ),
                    const SizedBox(width: AppSpacing.xs),
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
                    horizontal: AppSpacing.horizontal,
                  ),
                  children: [
                    _ChipFilter(
                      label: 'Semua',
                      aktif: _filterKelas == null,
                      onTap: () => setState(() => _filterKelas = null),
                    ),
                    for (final k in kelasAda)
                      _ChipFilter(
                        label: Penyakit.namaDariId(k),
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
                            'penyakit/lahan lain.',
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _muatUlang(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.horizontal,
                            0,
                            AppSpacing.horizontal,
                            AppSpacing.lg,
                          ),
                          itemCount: tersusun.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.smPlus),
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
          borderRadius: BorderRadius.circular(AppRadius.kecil),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.smPlus,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: aktif ? context.palet.primary : context.palet.card,
              borderRadius: BorderRadius.circular(AppRadius.kecil),
              border: Border.all(
                color: aktif ? context.palet.primary : context.palet.border,
              ),
            ),
            child: Text(
              label,
              style: context.teks.labelMedium?.copyWith(
                color: aktif
                    ? context.palet.onPrimary
                    : context.palet.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PemilihTanggal extends StatelessWidget {
  const _PemilihTanggal({required this.nilai, required this.onUbah});

  final _RentangTanggal nilai;
  final ValueChanged<_RentangTanggal> onUbah;

  static const _label = {
    _RentangTanggal.semua: 'Semua Waktu',
    _RentangTanggal.tujuhHari: '7 Hari',
    _RentangTanggal.tigaPuluhHari: '30 Hari',
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_RentangTanggal>(
      initialValue: nilai,
      tooltip: 'Filter berdasarkan tanggal',
      onSelected: onUbah,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        for (final e in _RentangTanggal.values)
          PopupMenuItem(
            value: e,
            child: Text(_label[e]!),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: nilai != _RentangTanggal.semua
              ? context.palet.accent
              : context.palet.card,
          borderRadius: BorderRadius.circular(AppRadius.kecil),
          border: Border.all(color: context.palet.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.date_range_outlined,
              size: 16,
              color: context.palet.primary,
            ),
            const SizedBox(width: 4),
            Text(
              _label[nilai]!,
              style: context.teks.labelMedium?.copyWith(
                color: context.palet.primaryDark,
              ),
            ),
          ],
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
    _Urutan.keyakinan: 'Skor',
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
          color: context.palet.card,
          borderRadius: BorderRadius.circular(AppRadius.kecil),
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
                color: context.palet.primaryDark,
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
        ? (riwayat.penyakit?.nama ?? Penyakit.namaDariId(riwayat.idPenyakit))
        : 'Belum meyakinkan';
    final yakin = riwayat.keyakinan * 100;
    final warna = dikenali
        ? context.warnaKeyakinan(yakin)
        : context.palet.warning;

    return Semantics(
      button: true,
      label:
          '$nama, keyakinan ${yakin.toStringAsFixed(2)} persen, '
          '${FormatWaktu.relatif(riwayat.waktu)}',
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sedang),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.smPlus),
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
                const SizedBox(width: AppSpacing.smPlus),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: context.teks.titleMedium?.copyWith(color: warna),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Skor ${yakin.toStringAsFixed(1)}% · '
                        '${FormatWaktu.ringkas(riwayat.waktu)}',
                        style: context.teks.bodySmall,
                      ),
                      if (riwayat.namaPetak != null &&
                          riwayat.namaPetak!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.grass_outlined,
                              size: 13,
                              color: context.palet.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                riwayat.namaPetak!,
                                style: context.teks.labelSmall?.copyWith(
                                  color: context.palet.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
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
