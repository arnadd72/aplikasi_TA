import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/catatan_lapangan_repository.dart';
import '../data/database_helper.dart';
import '../logic/photo_quality_checker.dart';
import '../logic/tflite_classifier.dart';
import '../models/catatan_lapangan.dart';
import '../models/hasil_identifikasi.dart';
import '../models/penyakit.dart';
import '../theme/app_tokens.dart';
import '../utils/format_waktu.dart';
import '../widgets/komponen.dart';
import 'detail_penyakit_screen.dart';
import 'detail_riwayat_screen.dart';
import 'form_pengamatan_screen.dart';
import 'form_petak_screen.dart';
import 'hasil_screen.dart';
import 'informasi_screen.dart';
import 'jadwal_perawatan_screen.dart';
import 'kamera_identifikasi_screen.dart';
import 'panduan_foto_screen.dart';
import 'pengaturan_screen.dart';
import 'petak_screen.dart';
import 'photo_preview_screen.dart';
import 'riwayat_screen.dart';
import 'timeline_petak_screen.dart';

/// Halaman Beranda sesuai PRD F-02 dan S-03 ("Clean Agricultural Utility").
///
/// Komponen utama:
/// 1. Header sapaan ("Selamat datang", "Pantau kesehatan tanaman padi Anda."),
///    indikator status offline, dan ikon Pengaturan.
/// 2. Kartu tindakan utama ("Periksa Kesehatan Daun Padi", tombol
///    "Identifikasi Sekarang", serta pintasan Kamera, Galeri, Panduan Foto).
/// 3. Kartu Lahan Aktif (atau tindakan "Tambahkan Lahan" bila belum ada).
/// 4. Hasil Identifikasi Terakhir (atau panduan identifikasi pertama bila kosong).
/// 5. Pengamatan Terbaru & Jadwal Perawatan Terdekat bila tersedia.
/// 6. Pintasan Panduan Penyakit dengan foto asli tanaman padi.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onPindahTab});

  final ValueChanged<int>? onPindahTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final TfliteClassifier _classifier = TfliteClassifier();

  bool _memproses = false;
  String? _pathFotoMemproses;
  bool _modelSiap = false;
  String? _pesanError;

  List<Petak> _daftarLahan = const [];
  List<Riwayat> _riwayatTerbaru = const [];
  List<CatatanPengamatan> _pengamatanTerbaru = const [];
  List<JadwalPerawatan> _jadwalMendatang = const [];
  List<Penyakit> _daftarPenyakit = const [];

  @override
  void initState() {
    super.initState();
    _muatModel();
    _muatDataRingkasan();
    DatabaseHelper.instance.perubahanRiwayat.addListener(_muatDataRingkasan);
  }

  @override
  void dispose() {
    DatabaseHelper.instance.perubahanRiwayat.removeListener(_muatDataRingkasan);
    _classifier.tutup();
    super.dispose();
  }

  Future<void> _muatModel() async {
    final siap = await _classifier.muat();
    if (!mounted) return;
    setState(() => _modelSiap = siap);
  }

  Future<void> _muatDataRingkasan() async {
    try {
      final lahan = await DatabaseHelper.instance.semuaPetak();
      final riwayat = await DatabaseHelper.instance.semuaRiwayat(batas: 3);
      final pengamatan = await DatabaseHelper.instance.semuaPengamatan(batas: 2);
      final jadwal = await DatabaseHelper.instance.semuaJadwalMendatang(batas: 3);
      final penyakit = await DatabaseHelper.instance.semuaPenyakit();
      if (!mounted) return;
      setState(() {
        _daftarLahan = lahan;
        _riwayatTerbaru = riwayat;
        _pengamatanTerbaru = pengamatan;
        _jadwalMendatang = jadwal;
        _daftarPenyakit = penyakit;
      });
    } on Object catch (e) {
      debugPrint('[Home] gagal memuat ringkasan lokal: $e');
    }
  }

  Future<void> _ambilFoto(ImageSource sumber, {int? idPetakAwal}) async {
    if (_memproses) return;
    setState(() => _pesanError = null);

    try {
      final XFile? foto = await _picker.pickImage(
        source: sumber,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: sumber == ImageSource.camera ? 92 : null,
      );
      if (foto == null) return;

      if (!mounted) return;
      final kualitas = await Navigator.of(context).push<KualitasFoto>(
        MaterialPageRoute(
          builder: (_) => PhotoPreviewScreen(pathFoto: foto.path),
        ),
      );
      if (kualitas == null || !mounted) return;

      setState(() {
        _memproses = true;
        _pathFotoMemproses = foto.path;
      });

      final path = await DatabaseHelper.instance.salinFotoKeAplikasi(foto.path);
      final mentah = await _classifier.identifikasi(path);
      final idRiwayat = await DatabaseHelper.instance.simpanRiwayat(
        Riwayat(
          pathFoto: mentah.pathFoto,
          idPenyakit: mentah.tidakDikenali ? '' : mentah.idPenyakit,
          keyakinan: mentah.keyakinan,
          waktu: mentah.waktu,
          idPetak: idPetakAwal,
          status: mentah.tidakDikenali
              ? StatusIdentifikasi.tidakPasti
              : mentah.idPenyakit == 'normal'
              ? StatusIdentifikasi.sehat
              : StatusIdentifikasi.terklasifikasi,
          aturan: mentah.aturan,
          waktuPraprosesMs: mentah.waktuPraprosesMs,
          waktuInferensiMs: mentah.waktuInferensiMs,
          waktuTotalMs: mentah.waktuTotalMs,
          fotoGelap: kualitas.terlaluGelap,
          fotoBuram: kualitas.buram,
          modelVersion: TfliteClassifier.versiModel,
          probabilitasJson: jsonEncode({
            for (final item in mentah.semuaProbabilitas)
              item.idPenyakit: item.nilai,
          }),
        ),
      );

      final hasil = HasilIdentifikasi(
        idPenyakit: mentah.idPenyakit,
        keyakinan: mentah.keyakinan,
        semuaProbabilitas: mentah.semuaProbabilitas,
        tidakDikenali: mentah.tidakDikenali,
        waktuInferensiMs: mentah.waktuInferensiMs,
        waktuPraprosesMs: mentah.waktuPraprosesMs,
        waktuTotalMs: mentah.waktuTotalMs,
        aturan: mentah.aturan,
        peringatanKualitas: kualitas.peringatan,
        pathFoto: mentah.pathFoto,
        waktu: mentah.waktu,
        idRiwayat: idRiwayat,
        idPetak: idPetakAwal,
      );

      if (!mounted) return;
      setState(() {
        _memproses = false;
        _pathFotoMemproses = null;
      });
      await _muatDataRingkasan();

      if (!mounted) return;
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => HasilScreen(hasil: hasil)));
      if (mounted) await _muatDataRingkasan();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _memproses = false;
        _pathFotoMemproses = null;
        _pesanError = e.toString();
      });
    }
  }

  Future<void> _buka(Widget layar) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => layar));
    if (mounted) await _muatDataRingkasan();
  }

  Future<void> _tambahLahanBaru() async {
    final ditambah = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const FormPetakScreen(
          repository: DatabaseCatatanLapanganRepository(),
        ),
      ),
    );
    if (ditambah == true && mounted) {
      await _muatDataRingkasan();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                await _muatModel();
                await _muatDataRingkasan();
              },
              child: CustomScrollView(
                cacheExtent: 1000,
                slivers: [
                  SliverToBoxAdapter(
                    child: _HeaderBeranda(
                      modelSiap: _modelSiap,
                      onBukaPengaturan: () => _buka(const PengaturanScreen()),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.horizontal,
                      0,
                      AppSpacing.horizontal,
                      AppSpacing.xl,
                    ),
                    sliver: SliverList.list(
                      children: [
                        _KartuTindakanUtama(
                          aktif: !_memproses,
                          modelSiap: _modelSiap,
                          onIdentifikasiSekarang: () =>
                              _buka(const KameraIdentifikasiScreen()),
                          onKamera: () => _ambilFoto(ImageSource.camera),
                          onGaleri: () => _ambilFoto(ImageSource.gallery),
                          onPanduan: () => _buka(const PanduanFotoScreen()),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (!_modelSiap) const _PeringatanModel(),
                        if (_pesanError != null)
                          KartuPesan(
                            warna: context.palet.destructive,
                            ikon: Icons.error_outline,
                            judul: 'Identifikasi gagal',
                            isi: _pesanError!,
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                          ),
                        _BagianLahanAktif(
                          daftarLahan: _daftarLahan,
                          onTambahLahan: _tambahLahanBaru,
                          onLihatSemuaLahan: () {
                            if (widget.onPindahTab != null) {
                              widget.onPindahTab!(1);
                            } else {
                              _buka(const PetakScreen());
                            }
                          },
                          onBukaDetailLahan: (petak) => _buka(
                            TimelinePetakScreen(
                              petak: petak,
                              repository:
                                  const DatabaseCatatanLapanganRepository(),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _BagianIdentifikasiTerbaru(
                          riwayatTerbaru: _riwayatTerbaru,
                          onLihatSemuaRiwayat: () {
                            if (widget.onPindahTab != null) {
                              widget.onPindahTab!(2);
                            } else {
                              _buka(const RiwayatScreen());
                            }
                          },
                          onBukaDetail: (r) =>
                              _buka(DetailRiwayatScreen(riwayat: r)),
                        ),
                        if (_pengamatanTerbaru.isNotEmpty ||
                            _daftarLahan.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.lg),
                          _BagianPengamatanTerbaru(
                            daftar: _pengamatanTerbaru,
                            daftarLahan: _daftarLahan,
                            onTambahPengamatan: () =>
                                _buka(const FormPengamatanScreen()),
                          ),
                        ],
                        if (_jadwalMendatang.isNotEmpty ||
                            _daftarLahan.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.lg),
                          _BagianJadwalTerdekat(
                            jadwal: _jadwalMendatang,
                            onBukaSemuaJadwal: () =>
                                _buka(const JadwalPerawatanScreen()),
                            onTandaiSelesai: (item) async {
                              if (item.idJadwal == null) return;
                              await DatabaseHelper.instance.ubahStatusJadwal(
                                item.idJadwal!,
                                true,
                              );
                              await _muatDataRingkasan();
                            },
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        _BagianPintasanPanduan(
                          daftarPenyakit: _daftarPenyakit,
                          onLihatSemuaPanduan: () {
                            if (widget.onPindahTab != null) {
                              widget.onPindahTab!(3);
                            } else {
                              _buka(const InformasiScreen());
                            }
                          },
                          onBukaPenyakit: (penyakit) =>
                              _buka(DetailPenyakitScreen(penyakit: penyakit)),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const _CaraPakai(),
                        const SizedBox(height: AppSpacing.md),
                        const _CatatanOffline(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_memproses)
              _LapisanMemproses(pathFoto: _pathFotoMemproses),
          ],
        ),
      ),
    );
  }
}

/// Area atas Beranda (PRD S-03):
/// - Sapaan "Selamat datang"
/// - Subteks "Pantau kesehatan tanaman padi Anda."
/// - Status offline & ikon pengaturan
class _HeaderBeranda extends StatelessWidget {
  const _HeaderBeranda({
    required this.modelSiap,
    required this.onBukaPengaturan,
  });

  final bool modelSiap;
  final VoidCallback onBukaPengaturan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.horizontal,
        AppSpacing.md,
        AppSpacing.horizontal,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.palet.primary,
                borderRadius: BorderRadius.circular(AppRadius.kecil),
              ),
              child: Icon(
                Icons.eco_outlined,
                color: context.palet.onPrimary,
                size: AppIkon.besar,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.smPlus),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat datang',
                  style: context.teks.labelMedium?.copyWith(
                    color: context.palet.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Pantau kesehatan tanaman padi Anda.',
                  style: context.teks.titleMedium?.copyWith(
                    color: context.palet.primaryDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            tooltip: 'Pengaturan',
            onPressed: onBukaPengaturan,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }
}

/// Kartu tindakan utama sesuai PRD S-03:
/// - Judul: "Periksa Kesehatan Daun Padi"
/// - Subteks: "Ambil foto daun untuk melihat kemungkinan penyakit."
/// - Tombol utama: "Identifikasi Sekarang" + pintasan langsung Kamera & Galeri.
class _KartuTindakanUtama extends StatelessWidget {
  const _KartuTindakanUtama({
    required this.aktif,
    required this.modelSiap,
    required this.onIdentifikasiSekarang,
    required this.onKamera,
    required this.onGaleri,
    required this.onPanduan,
  });

  final bool aktif;
  final bool modelSiap;
  final VoidCallback onIdentifikasiSekarang;
  final VoidCallback onKamera;
  final VoidCallback onGaleri;
  final VoidCallback onPanduan;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.horizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.palet.accent,
                    borderRadius: BorderRadius.circular(AppRadius.kecil),
                  ),
                  child: Text(
                    'Identifikasi AI Offline',
                    style: context.teks.labelSmall?.copyWith(
                      color: context.palet.onAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (modelSiap)
                  Lencana(
                    teks: 'Offline · Siap',
                    warna: context.palet.success,
                    ikon: Icons.offline_pin_outlined,
                  )
                else
                  Lencana(
                    teks: 'Model kosong',
                    warna: context.palet.warning,
                    ikon: Icons.warning_amber_rounded,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.smPlus),
            Text(
              'Periksa Kesehatan Daun Padi',
              style: context.teks.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Ambil foto daun untuk melihat kemungkinan penyakit.',
              style: context.teks.bodyMedium?.copyWith(
                color: context.palet.mutedForeground,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              button: true,
              enabled: aktif,
              label: 'Identifikasi sekarang',
              child: FilledButton.icon(
                onPressed: aktif ? onIdentifikasiSekarang : null,
                icon: const Icon(Icons.center_focus_strong_outlined),
                label: const Text('Identifikasi Sekarang'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    enabled: aktif,
                    label: 'Ambil foto daun dengan kamera',
                    child: OutlinedButton.icon(
                      onPressed: aktif ? onKamera : null,
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: const Text('Ambil Foto Daun'),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Semantics(
                    button: true,
                    enabled: aktif,
                    label: 'Pilih foto daun dari galeri',
                    child: OutlinedButton.icon(
                      onPressed: aktif ? onGaleri : null,
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Pilih dari Galeri'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onPanduan,
                icon: const Icon(Icons.help_outline_rounded, size: 18),
                label: const Text('Panduan Ambil Foto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu Lahan Aktif sesuai Business Rules F-02:
/// Jika belum memiliki lahan, tampilkan tindakan "Tambahkan Lahan".
class _BagianLahanAktif extends StatelessWidget {
  const _BagianLahanAktif({
    required this.daftarLahan,
    required this.onTambahLahan,
    required this.onLihatSemuaLahan,
    required this.onBukaDetailLahan,
  });

  final List<Petak> daftarLahan;
  final VoidCallback onTambahLahan;
  final VoidCallback onLihatSemuaLahan;
  final ValueChanged<Petak> onBukaDetailLahan;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text('Lahan Aktif', style: context.teks.titleLarge),
            ),
            if (daftarLahan.isNotEmpty)
              TextButton(
                onPressed: onLihatSemuaLahan,
                child: const Text('Kelola Lahan'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (daftarLahan.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.grass_outlined,
                        color: context.palet.primary,
                        size: AppIkon.besar,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Belum ada lahan terdaftar',
                          style: context.teks.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Tambahkan lahan untuk mencatat varietas, umur tanaman '
                    '(HST), pengamatan lapangan, dan jadwal perawatan.',
                    style: context.teks.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: onTambahLahan,
                    icon: const Icon(Icons.add),
                    label: const Text('Tambahkan Lahan'),
                  ),
                ],
              ),
            ),
          )
        else
          Builder(
            builder: (context) {
              final utama = daftarLahan.first;
              final hst = utama.umurHariSetelahTanam();
              final fase = utama.faseTanam();
              return Card(
                child: InkWell(
                  onTap: () => onBukaDetailLahan(utama),
                  borderRadius: BorderRadius.circular(AppRadius.sedang),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                utama.nama,
                                style: context.teks.titleMedium,
                              ),
                            ),
                            if (hst != null)
                              Lencana(
                                teks: '$hst HST',
                                warna: context.palet.primary,
                                ikon: Icons.calendar_today_outlined,
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: 4,
                          children: [
                            if (utama.varietas.isNotEmpty)
                              Text(
                                'Varietas: ${utama.varietas}',
                                style: context.teks.bodySmall,
                              ),
                            if (utama.labelLuas != null)
                              Text(
                                'Luas: ${utama.labelLuas}',
                                style: context.teks.bodySmall,
                              ),
                            if (fase != null)
                              Text(fase, style: context.teks.bodySmall),
                          ],
                        ),
                        if (daftarLahan.length > 1) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '+${daftarLahan.length - 1} lahan lainnya terdaftar',
                            style: context.teks.labelSmall?.copyWith(
                              color: context.palet.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Bagian Hasil Identifikasi Terakhir sesuai PRD F-02 & S-03.
class _BagianIdentifikasiTerbaru extends StatelessWidget {
  const _BagianIdentifikasiTerbaru({
    required this.riwayatTerbaru,
    required this.onLihatSemuaRiwayat,
    required this.onBukaDetail,
  });

  final List<Riwayat> riwayatTerbaru;
  final VoidCallback onLihatSemuaRiwayat;
  final ValueChanged<Riwayat> onBukaDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Identifikasi Terakhir',
                style: context.teks.titleLarge,
              ),
            ),
            TextButton(
              onPressed: onLihatSemuaRiwayat,
              child: const Text('Riwayat'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (riwayatTerbaru.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.fact_check_outlined,
                    color: context.palet.primary,
                    size: AppIkon.besar,
                  ),
                  const SizedBox(width: AppSpacing.smPlus),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Belum ada hasil pemeriksaan',
                          style: context.teks.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tekan tombol Identifikasi Sekarang di atas untuk '
                          'memeriksa foto daun padi pertama Anda.',
                          style: context.teks.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          for (final item in riwayatTerbaru.take(2))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Card(
                child: InkWell(
                  onTap: () => onBukaDetail(item),
                  borderRadius: BorderRadius.circular(AppRadius.sedang),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.smPlus),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.kecil),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: ImageFile(path: item.pathFoto),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.smPlus),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.idPenyakit.isEmpty
                                    ? 'Hasil Belum Meyakinkan'
                                    : (item.penyakit?.nama ??
                                          Penyakit.namaDariId(item.idPenyakit)),
                                style: context.teks.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${(item.keyakinan * 100).toStringAsFixed(0)}% · '
                                '${FormatWaktu.ringkas(item.waktu)}'
                                '${item.namaPetak != null ? ' · ${item.namaPetak}' : ''}',
                                style: context.teks.labelMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: context.palet.mutedForeground,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

/// Pengamatan terbaru (PRD S-03 Area Tengah).
class _BagianPengamatanTerbaru extends StatelessWidget {
  const _BagianPengamatanTerbaru({
    required this.daftar,
    required this.daftarLahan,
    required this.onTambahPengamatan,
  });

  final List<CatatanPengamatan> daftar;
  final List<Petak> daftarLahan;
  final VoidCallback onTambahPengamatan;

  @override
  Widget build(BuildContext context) {
    final petaNama = {
      for (final l in daftarLahan)
        if (l.idPetak != null) l.idPetak!: l.nama,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text('Pengamatan Terbaru', style: context.teks.titleLarge),
            ),
            if (daftarLahan.isNotEmpty)
              TextButton.icon(
                onPressed: onTambahPengamatan,
                icon: const Icon(Icons.note_add_outlined, size: 18),
                label: const Text('Catat'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (daftar.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                daftarLahan.isEmpty
                    ? 'Tambahkan lahan terlebih dahulu untuk mencatat hasil pengamatan lapangan.'
                    : 'Belum ada catatan pengamatan manual. Tekan "Catat" untuk mencatat perkembangan tanaman.',
                style: context.teks.bodySmall,
              ),
            ),
          )
        else
          Builder(
            builder: (context) {
              final terbaru = daftar.first;
              final namaLahan = petaNama[terbaru.idPetak] ?? 'Lahan';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 18,
                            color: context.palet.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              '$namaLahan · ${terbaru.kondisiTanaman}',
                              style: context.teks.titleSmall,
                            ),
                          ),
                          Text(
                            FormatWaktu.angka(terbaru.tanggal),
                            style: context.teks.labelSmall,
                          ),
                        ],
                      ),
                      if (terbaru.gejalaDiamati.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Gejala: ${terbaru.gejalaDiamati}',
                          style: context.teks.bodySmall,
                        ),
                      ],
                      if (terbaru.tindakanDilakukan.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Tindakan: ${terbaru.tindakanDilakukan}',
                          style: context.teks.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Jadwal perawatan terdekat (PRD F-02, F-16, S-03, S-16).
class _BagianJadwalTerdekat extends StatelessWidget {
  const _BagianJadwalTerdekat({
    required this.jadwal,
    required this.onBukaSemuaJadwal,
    required this.onTandaiSelesai,
  });

  final List<JadwalPerawatan> jadwal;
  final VoidCallback onBukaSemuaJadwal;
  final ValueChanged<JadwalPerawatan> onTandaiSelesai;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Jadwal Perawatan Terdekat',
                style: context.teks.titleLarge,
              ),
            ),
            TextButton(
              onPressed: onBukaSemuaJadwal,
              child: const Text('Kelola Jadwal'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (jadwal.isEmpty)
          Card(
            child: InkWell(
              onTap: onBukaSemuaJadwal,
              borderRadius: BorderRadius.circular(AppRadius.sedang),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_available_outlined,
                      color: context.palet.primary,
                      size: AppIkon.besar,
                    ),
                    const SizedBox(width: AppSpacing.smPlus),
                    Expanded(
                      child: Text(
                        'Belum ada jadwal kegiatan terdekat. Ketuk untuk mengatur '
                        'jadwal pemeriksaan daun, pemupukan, atau pengairan.',
                        style: context.teks.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          for (final item in jadwal.take(2))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Card(
                child: ListTile(
                  onTap: onBukaSemuaJadwal,
                  leading: Icon(
                    Icons.event_note_outlined,
                    color: context.palet.primary,
                  ),
                  title: Text(item.judul, style: context.teks.titleSmall),
                  subtitle: Text(
                    '${item.namaPetak ?? 'Lahan'} · '
                    '${FormatWaktu.panjang(item.tanggalJadwal)}',
                    style: context.teks.labelMedium,
                  ),
                  trailing: IconButton(
                    tooltip: 'Tandai selesai',
                    onPressed: () => onTandaiSelesai(item),
                    icon: Icon(
                      Icons.check_circle_outline,
                      color: context.palet.primary,
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

/// Pintasan Panduan Penyakit dengan fotografi daun padi asli (PRD F-02 & S-03).
class _BagianPintasanPanduan extends StatelessWidget {
  const _BagianPintasanPanduan({
    required this.daftarPenyakit,
    required this.onLihatSemuaPanduan,
    required this.onBukaPenyakit,
  });

  final List<Penyakit> daftarPenyakit;
  final VoidCallback onLihatSemuaPanduan;
  final ValueChanged<Penyakit> onBukaPenyakit;

  static const _fallbackKelas = <(String, String, String)>[
    ('blas', 'C01', 'Blas (Blas Daun)'),
    ('hawar_daun_bakteri', 'C02', 'Hawar Daun Bakteri (HDB)'),
    ('bercak_cokelat', 'C03', 'Bercak Cokelat'),
    ('normal', 'C04', 'Daun Sehat'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text('Info Penyakit', style: context.teks.titleLarge),
            ),
            TextButton(
              onPressed: onLihatSemuaPanduan,
              child: const Text('Buka Pustaka'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (daftarPenyakit.isNotEmpty)
          for (final p in daftarPenyakit)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Card(
                child: InkWell(
                  onTap: () => onBukaPenyakit(p),
                  borderRadius: BorderRadius.circular(AppRadius.sedang),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.smPlus),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.kecil),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: Image.asset(
                              p.pathGambar,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => ColoredBox(
                                color: context.palet.muted,
                                child: Icon(
                                  Icons.eco_outlined,
                                  color: context.palet.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.smPlus),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${p.kodeKelas} · ${p.nama}',
                                style: context.teks.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.namaLatin,
                                style: context.teks.labelMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: context.palet.mutedForeground,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
        else
          for (final (id, kode, nama) in _fallbackKelas)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Card(
                child: InkWell(
                  onTap: onLihatSemuaPanduan,
                  borderRadius: BorderRadius.circular(AppRadius.sedang),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.smPlus),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.kecil),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Image.asset(
                              Penyakit.gambarDariId(id),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => ColoredBox(
                                color: context.palet.muted,
                                child: Icon(
                                  Icons.eco_outlined,
                                  color: context.palet.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.smPlus),
                        Expanded(
                          child: Text(
                            '$kode · $nama',
                            style: context.teks.titleSmall,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: context.palet.mutedForeground,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _PeringatanModel extends StatelessWidget {
  const _PeringatanModel();

  @override
  Widget build(BuildContext context) {
    return KartuPesan(
      warna: context.palet.warning,
      ikon: Icons.warning_amber_rounded,
      judul: 'Model TensorFlow Lite belum siap',
      isi:
          'Pastikan berkas assets/models/padi_mobilenetv2.tflite tersedia '
          'di dalam paket aplikasi.',
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
    );
  }
}

class _CaraPakai extends StatelessWidget {
  const _CaraPakai();

  static const _langkah = <(String, String)>[
    (
      'Ambil foto daun',
      'Fokuskan kamera pada satu helai daun yang bergejala dengan cahaya cukup.',
    ),
    (
      'Periksa pratinjau',
      'Pastikan gambar tidak buram lalu konfirmasi untuk menjalankan analisis.',
    ),
    (
      'Baca hasil & panduan',
      'Jika skor mencapai minimal 70%, sistem menampilkan kemungkinan kelas dan tindakan awal.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return KartuBagian(
      judul: 'Cara pakai',
      ikon: Icons.help_outline_rounded,
      anak: Column(
        children: [
          for (var i = 0; i < _langkah.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.smPlus),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.palet.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: context.teks.labelMedium?.copyWith(
                      color: context.palet.onAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.smPlus),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_langkah[i].$1, style: context.teks.titleSmall),
                      const SizedBox(height: 2),
                      Text(_langkah[i].$2, style: context.teks.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CatatanOffline extends StatelessWidget {
  const _CatatanOffline();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.palet.muted,
        borderRadius: BorderRadius.circular(AppRadius.sedang),
        border: Border.all(color: context.palet.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.offline_bolt_outlined,
            color: context.palet.primary,
            size: AppIkon.sedang,
          ),
          const SizedBox(width: AppSpacing.smPlus),
          Expanded(
            child: Text(
              'Berjalan tanpa internet. Model MobileNetV2 dan basis pengetahuan '
              'penanganan tersimpan di perangkat Anda.',
              style: context.teks.bodySmall?.copyWith(
                color: context.palet.cardForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tampilan S-06 Proses Identifikasi sesuai PRD:
/// - Thumbnail foto
/// - Loading indicator
/// - Teks "Sedang memeriksa foto daun"
/// - Teks pendukung "Proses dilakukan di perangkat Anda."
class _LapisanMemproses extends StatelessWidget {
  const _LapisanMemproses({this.pathFoto});

  final String? pathFoto;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Sedang memeriksa foto daun. Proses dilakukan di perangkat Anda.',
      child: ColoredBox(
        color: Colors.black54,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Card(
              margin: const EdgeInsets.all(AppSpacing.lg),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pathFoto != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.kecil),
                        child: SizedBox(
                          width: 96,
                          height: 96,
                          child: ImageFile(path: pathFoto!),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Sedang memeriksa foto daun',
                      textAlign: TextAlign.center,
                      style: context.teks.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Proses dilakukan di perangkat Anda.',
                      textAlign: TextAlign.center,
                      style: context.teks.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
