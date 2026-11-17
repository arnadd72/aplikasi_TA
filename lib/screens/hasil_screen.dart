import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/catatan_lapangan.dart';
import '../models/hasil_identifikasi.dart';
import '../models/penyakit.dart';
import '../theme/app_tokens.dart';
import '../utils/format_waktu.dart';
import '../widgets/komponen.dart';
import 'rekomendasi_screen.dart';

/// Halaman Hasil Identifikasi sesuai PRD F-06, F-07, dan S-07.
///
/// Elemen utama:
/// 1. Foto daun yang dianalisis.
/// 2. Nama penyakit teratas sebagai elemen paling menonjol ("Kemungkinan: ...").
/// 3. Skor keyakinan model sebagai informasi sekunder.
/// 4. Penjelasan singkat & daftar gejala umum.
/// 5. Pilihan menyimpan catatan & mengaitkan hasil ke Lahan ("Simpan Hasil").
/// 6. Tombol "Lihat Penanganan" / rekomendasi dan "Identifikasi Foto Lain".
class HasilScreen extends StatefulWidget {
  const HasilScreen({super.key, required this.hasil});

  final HasilIdentifikasi hasil;

  @override
  State<HasilScreen> createState() => _HasilScreenState();
}

class _HasilScreenState extends State<HasilScreen> {
  Penyakit? _penyakit;
  List<Petak> _daftarLahan = const [];
  int? _idPetakTerpilih;
  final TextEditingController _catatanController = TextEditingController();
  bool _memuat = true;
  bool _menyimpan = false;

  @override
  void initState() {
    super.initState();
    _idPetakTerpilih = widget.hasil.idPetak;
    _muatData();
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _muatData() async {
    Penyakit? p;
    List<Petak> lahan = const [];
    if (!widget.hasil.tidakDikenali && widget.hasil.idPenyakit.isNotEmpty) {
      try {
        p = await DatabaseHelper.instance.penyakitById(widget.hasil.idPenyakit);
      } on Object catch (e) {
        debugPrint('[Hasil] gagal memuat penyakit: $e');
        p = null;
      }
    }
    try {
      lahan = await DatabaseHelper.instance.semuaPetak();
    } on Object catch (e) {
      debugPrint('[Hasil] gagal memuat lahan: $e');
    }
    if (!mounted) return;
    setState(() {
      _penyakit = p;
      _daftarLahan = lahan;
      _memuat = false;
    });
  }

  Future<void> _simpanHasil() async {
    final idRiwayat = widget.hasil.idRiwayat;
    if (idRiwayat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hasil pemeriksaan telah tersimpan.')),
      );
      return;
    }
    setState(() => _menyimpan = true);
    try {
      await DatabaseHelper.instance.perbaruiDetailRiwayat(
        idRiwayat: idRiwayat,
        idPetak: _idPetakTerpilih,
        ubahPetak: true,
        catatanPengguna: _catatanController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hasil dan catatan berhasil disimpan ke Riwayat.'),
        ),
      );
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan catatan: $e')));
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  void _bukaRekomendasi() {
    final p =
        _penyakit ??
        Penyakit(
          idPenyakit: widget.hasil.idPenyakit,
          labelModel: widget.hasil.idPenyakit,
          nama: Penyakit.namaDariId(widget.hasil.idPenyakit),
          namaLatin: '-',
          penyebab: '-',
          gejala: Penyakit.penjelasanDariId(widget.hasil.idPenyakit),
        );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RekomendasiScreen(penyakit: p)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasil = widget.hasil;

    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Identifikasi')),
      body: _memuat
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.horizontal,
                AppSpacing.md,
                AppSpacing.horizontal,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KartuFoto(
                    path: hasil.pathFoto,
                    labelSemantik: 'Foto daun yang diidentifikasi',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (hasil.peringatanKualitas.isNotEmpty) ...[
                    KartuPesan(
                      judul: hasil.peringatanKualitas.first,
                      isi:
                          'Hasil tetap diproses atas pilihan pengguna. '
                          'Ambil ulang foto bila bentuk gejala tidak terlihat jelas.',
                      warna: context.palet.warning,
                      ikon: Icons.warning_amber_rounded,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (hasil.tidakDikenali)
                    _KartuTidakDikenali(hasil: hasil)
                  else
                    _KartuHasil(hasil: hasil, penyakit: _penyakit),
                  const SizedBox(height: AppSpacing.md),
                  if (!hasil.tidakDikenali) ...[
                    Semantics(
                      button: true,
                      label: (_penyakit?.isSehat ?? hasil.idPenyakit == 'normal')
                          ? 'Lihat saran pemeliharaan'
                          : 'Lihat rekomendasi penanganan',
                      child: FilledButton.icon(
                        onPressed: _bukaRekomendasi,
                        icon: Icon(
                          (_penyakit?.isSehat ?? hasil.idPenyakit == 'normal')
                              ? Icons.verified_outlined
                              : Icons.medical_information_outlined,
                        ),
                        label: Text(
                          (_penyakit?.isSehat ?? hasil.idPenyakit == 'normal')
                              ? 'Lihat Saran Pemeliharaan'
                              : 'Lihat Rekomendasi Penanganan',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.smPlus),
                  ],
                  if (hasil.idRiwayat != null) ...[
                    _KartuSimpanLahanDanCatatan(
                      daftarLahan: _daftarLahan,
                      idPetakTerpilih: _idPetakTerpilih,
                      onPilihPetak: (v) => setState(() => _idPetakTerpilih = v),
                      catatanController: _catatanController,
                      menyimpan: _menyimpan,
                      onSimpan: _simpanHasil,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _CatatanTeknis(hasil: hasil),
                  const SizedBox(height: AppSpacing.md),
                  _TabelProbabilitas(
                    daftar: hasil.semuaProbabilitas,
                    terpilih: hasil.idPenyakit,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Identifikasi Foto Lain'),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Kartu hasil utama sesuai PRD F-07 & S-07:
/// - Nama penyakit sebagai elemen paling menonjol
/// - Skor keyakinan sebagai informasi sekunder
/// - Penjelasan singkat & daftar gejala umum
class _KartuHasil extends StatelessWidget {
  const _KartuHasil({required this.hasil, required this.penyakit});

  final HasilIdentifikasi hasil;
  final Penyakit? penyakit;

  @override
  Widget build(BuildContext context) {
    final sehat = (penyakit?.isSehat ?? false) || hasil.idPenyakit == 'normal';
    final nama = penyakit?.nama ?? Penyakit.namaDariId(hasil.idPenyakit);
    final kode = Penyakit.kodeDariId(hasil.idPenyakit);
    final yakin = hasil.keyakinanPersen;
    final warna = context.warnaKeyakinan(yakin);
    final teksStatus = yakin >= 85
        ? 'Keyakinan tinggi'
        : yakin >= 70
        ? 'Keyakinan cukup'
        : 'Keyakinan rendah';
    final gejalaButir = Penyakit.gejalaDaftarDariId(hasil.idPenyakit);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.horizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    sehat
                        ? 'Daun terdeteksi sehat'
                        : 'Kemungkinan teridentifikasi',
                    style: context.teks.titleMedium,
                  ),
                ),
                Lencana(
                  teks: teksStatus,
                  warna: warna,
                  ikon: yakin >= 85
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (kode != '-')
                  Lencana(
                    teks: 'Kelas $kode',
                    warna: context.palet.primary,
                    ikon: Icons.label_outline,
                  ),
                if (hasil.aturan.isNotEmpty)
                  Lencana(
                    teks: 'Aturan ${hasil.aturan}',
                    warna: warna,
                    ikon: Icons.rule_outlined,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.smPlus),
            Text(
              nama,
              style: context.teks.headlineMedium?.copyWith(color: warna),
            ),
            if (penyakit != null && penyakit!.namaLatin.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                penyakit!.namaLatin,
                style: context.teks.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.smPlus),
            Text(
              Penyakit.penjelasanDariId(hasil.idPenyakit),
              style: context.teks.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              label:
                  'Tingkat keyakinan '
                  '${yakin.toStringAsFixed(2)} persen, $teksStatus',
              child: ExcludeSemantics(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Skor keyakinan model (identifikasi awal)',
                            style: context.teks.labelMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            '${yakin.toStringAsFixed(2)}%',
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.teks.titleMedium?.copyWith(
                              color: warna,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pil),
                      child: LinearProgressIndicator(
                        value: hasil.keyakinan.clamp(0.0, 1.0),
                        minHeight: 8,
                        color: warna,
                        backgroundColor: context.palet.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0%', style: context.teks.labelSmall),
                        Expanded(
                          child: Text(
                            'ambang batas 70%',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.teks.labelSmall,
                          ),
                        ),
                        Text('100%', style: context.teks.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (gejalaButir.isNotEmpty) ...[
              const Divider(height: AppSpacing.lg),
              Text(
                sehat ? 'Ciri kondisi daun' : 'Gejala umum yang perlu dicocokkan',
                style: context.teks.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final butir in gejalaButir)
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
    );
  }
}

/// Kartu ketidakpastian sesuai PRD F-06 & S-07:
/// Teks wajib: "Hasil belum cukup meyakinkan. Coba ambil foto daun yang lebih jelas."
class _KartuTidakDikenali extends StatelessWidget {
  const _KartuTidakDikenali({required this.hasil});

  final HasilIdentifikasi hasil;

  static const _panduan = <String>[
    'Ambil foto dalam kondisi cukup cahaya dan hindari bayangan tajam.',
    'Pastikan satu helai daun yang bergejala menjadi objek utama.',
    'Fokuskan kamera dari jarak 15–25 cm agar permukaan daun tidak buram.',
    'Hindari latar belakang yang terlalu ramai oleh daun atau tanah lain.',
  ];

  @override
  Widget build(BuildContext context) {
    final warna = context.palet.warning;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.horizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Citra Tidak Dikenali',
                    style: context.teks.headlineSmall?.copyWith(color: warna),
                  ),
                ),
                Lencana(
                  teks: 'Di bawah 70%',
                  warna: warna,
                  ikon: Icons.help_outline,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Hasil belum cukup meyakinkan. Coba ambil foto daun yang lebih jelas.',
              style: context.teks.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Skor tertinggi model hanya '
              '${hasil.keyakinanPersen.toStringAsFixed(2)}% (di bawah ambang '
              'batas 70%). Aplikasi tidak menampilkan diagnosis agar tidak '
              'menyesatkan tindakan penanganan.',
              style: context.teks.bodySmall,
            ),
            const Divider(height: AppSpacing.lg),
            Text('Panduan foto ulang', style: context.teks.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            for (final p in _panduan)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: ExcludeSemantics(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: warna,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 2),
                    Expanded(child: Text(p, style: context.teks.bodySmall)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Kartu untuk mengaitkan hasil ke Lahan dan menambahkan catatan pengguna (PRD F-09 & S-07).
class _KartuSimpanLahanDanCatatan extends StatelessWidget {
  const _KartuSimpanLahanDanCatatan({
    required this.daftarLahan,
    required this.idPetakTerpilih,
    required this.onPilihPetak,
    required this.catatanController,
    required this.menyimpan,
    required this.onSimpan,
  });

  final List<Petak> daftarLahan;
  final int? idPetakTerpilih;
  final ValueChanged<int?> onPilihPetak;
  final TextEditingController catatanController;
  final bool menyimpan;
  final VoidCallback onSimpan;

  @override
  Widget build(BuildContext context) {
    return KartuBagian(
      judul: 'Simpan ke Lahan & Catatan',
      ikon: Icons.bookmark_added_outlined,
      anak: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<int?>(
            initialValue: idPetakTerpilih,
            decoration: const InputDecoration(
              labelText: 'Kaitkan dengan lahan (opsional)',
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Tanpa lahan'),
              ),
              for (final l in daftarLahan)
                DropdownMenuItem<int?>(
                  value: l.idPetak,
                  child: Text(l.nama),
                ),
            ],
            onChanged: onPilihPetak,
          ),
          const SizedBox(height: AppSpacing.smPlus),
          TextField(
            controller: catatanController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Catatan pengamatan (opsional)',
              hintText: 'Contoh: Ditemukan di sudut petak dekat saluran air',
            ),
          ),
          const SizedBox(height: AppSpacing.smPlus),
          OutlinedButton.icon(
            onPressed: menyimpan ? null : onSimpan,
            icon: const Icon(Icons.save_outlined),
            label: Text(menyimpan ? 'Menyimpan…' : 'Simpan Hasil'),
          ),
        ],
      ),
    );
  }
}

class _TabelProbabilitas extends StatelessWidget {
  const _TabelProbabilitas({required this.daftar, required this.terpilih});

  final List<ProbabilitasKelas> daftar;
  final String terpilih;

  @override
  Widget build(BuildContext context) {
    return KartuBagian(
      judul: 'Skor setiap kelas (0–100%)',
      ikon: Icons.bar_chart_rounded,
      anak: Column(
        children: [
          for (final p in daftar)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
              child: Semantics(
                label:
                    '${Penyakit.namaDariId(p.idPenyakit)}, '
                    '${p.persen.toStringAsFixed(2)} persen',
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              Penyakit.namaDariId(p.idPenyakit),
                              style: context.teks.bodySmall?.copyWith(
                                fontWeight: p.idPenyakit == terpilih
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: p.idPenyakit == terpilih
                                    ? context.palet.foreground
                                    : context.palet.mutedForeground,
                              ),
                            ),
                          ),
                          Text(
                            '${p.persen.toStringAsFixed(2)}%',
                            style: context.teks.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: p.idPenyakit == terpilih
                                  ? context.palet.primary
                                  : context.palet.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pil),
                        child: LinearProgressIndicator(
                          value: p.nilai.clamp(0.0, 1.0),
                          minHeight: 6,
                          color: p.idPenyakit == terpilih
                              ? context.palet.primary
                              : context.palet.border,
                          backgroundColor: context.palet.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Nilai softmax adalah skor keyakinan model pada empat kelas yang '
            'dilatih, bukan jaminan kepastian diagnosis.',
            style: context.teks.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _CatatanTeknis extends StatelessWidget {
  const _CatatanTeknis({required this.hasil});

  final HasilIdentifikasi hasil;

  @override
  Widget build(BuildContext context) {
    return KartuBagian(
      judul: 'Catatan teknis & batasan AI',
      ikon: Icons.memory_rounded,
      anak: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BarisLabelNilai(
            label: 'Prapemrosesan',
            nilai: '${hasil.waktuPraprosesMs} ms',
          ),
          BarisLabelNilai(
            label: 'Inferensi model',
            nilai: '${hasil.waktuInferensiMs} ms',
          ),
          BarisLabelNilai(
            label: 'Total proses',
            nilai: '${hasil.waktuTotalMs} ms',
          ),
          if (hasil.aturan.isNotEmpty)
            BarisLabelNilai(label: 'Aturan', nilai: hasil.aturan),
          BarisLabelNilai(
            label: 'Waktu identifikasi',
            nilai: FormatWaktu.ringkas(hasil.waktu),
          ),
          const BarisLabelNilai(
            label: 'Ukuran masukan',
            nilai: '224 x 224 piksel',
          ),
          const BarisLabelNilai(label: 'Model', nilai: 'MobileNetV2, TFLite'),
          const Divider(height: AppSpacing.lg),
          Text(
            'Hasil AI merupakan alat bantu pengambilan keputusan awal dan '
            'tidak menggantikan pemeriksaan penyuluh pertanian (PPL/POPT) '
            'atau laboratorium.',
            style: context.teks.bodySmall,
          ),
        ],
      ),
    );
  }
}
