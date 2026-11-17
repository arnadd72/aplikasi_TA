import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/hasil_identifikasi.dart';
import '../models/penyakit.dart';
import '../theme/app_tokens.dart';
import '../utils/format_waktu.dart';
import '../widgets/komponen.dart';
import 'rekomendasi_screen.dart';

/// Halaman hasil identifikasi (F-04) dan pintu ke rekomendasi (F-05).
///
/// Bila keyakinan berada di bawah ambang batas, aturan R5 menandai hasil
/// sebagai tidak dikenali dan layar menampilkan panduan pengambilan ulang
/// foto (F-06).
class HasilScreen extends StatefulWidget {
  const HasilScreen({super.key, required this.hasil});

  final HasilIdentifikasi hasil;

  @override
  State<HasilScreen> createState() => _HasilScreenState();
}

class _HasilScreenState extends State<HasilScreen> {
  Penyakit? _penyakit;
  bool _memuat = true;

  @override
  void initState() {
    super.initState();
    _muatPenyakit();
  }

  Future<void> _muatPenyakit() async {
    Penyakit? p;
    if (!widget.hasil.tidakDikenali && widget.hasil.idPenyakit.isNotEmpty) {
      // Kegagalan basis data tidak boleh mengunci layar pada indikator
      // memuat. Nama kelas mentah tetap ditampilkan apa adanya.
      try {
        p = await DatabaseHelper.instance.penyakitById(widget.hasil.idPenyakit);
      } on Object catch (e) {
        debugPrint('[Hasil] gagal memuat penyakit: $e');
        p = null;
      }
    }
    if (!mounted) return;
    setState(() {
      _penyakit = p;
      _memuat = false;
    });
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
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
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
                  _CatatanTeknis(hasil: hasil),
                  const SizedBox(height: AppSpacing.md),
                  _TabelProbabilitas(
                    daftar: hasil.semuaProbabilitas,
                    terpilih: hasil.idPenyakit,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (!hasil.tidakDikenali && _penyakit != null) ...[
                    Semantics(
                      button: true,
                      label: _penyakit!.isSehat
                          ? 'Lihat saran pemeliharaan'
                          : 'Lihat rekomendasi penanganan',
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                RekomendasiScreen(penyakit: _penyakit!),
                          ),
                        ),
                        icon: Icon(
                          _penyakit!.isSehat
                              ? Icons.verified_outlined
                              : Icons.medical_information_outlined,
                        ),
                        label: Text(
                          _penyakit!.isSehat
                              ? 'Lihat Saran Pemeliharaan'
                              : 'Lihat Rekomendasi Penanganan',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm + 2),
                  ],
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

class _KartuHasil extends StatelessWidget {
  const _KartuHasil({required this.hasil, required this.penyakit});

  final HasilIdentifikasi hasil;
  final Penyakit? penyakit;

  @override
  Widget build(BuildContext context) {
    final sehat = (penyakit?.isSehat ?? false) || hasil.idPenyakit == 'normal';
    final nama = penyakit?.nama ?? (sehat ? 'Daun Sehat' : hasil.idPenyakit);
    final yakin = hasil.keyakinanPersen;
    final warna = context.warnaKeyakinan(yakin);
    final teksStatus = yakin >= 85
        ? 'Keyakinan tinggi'
        : yakin >= 70
        ? 'Keyakinan cukup'
        : 'Keyakinan rendah';

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
                  child: Text(
                    sehat
                        ? 'Daun terdeteksi sehat'
                        : 'Penyakit teridentifikasi',
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
            if (hasil.aturan.isNotEmpty) ...[
              Lencana(
                teks: 'Aturan ${hasil.aturan}',
                warna: warna,
                ikon: Icons.rule_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
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
            const SizedBox(height: AppSpacing.md + 2),
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
                            'Tingkat keyakinan',
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
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pil),
                      child: LinearProgressIndicator(
                        value: hasil.keyakinan.clamp(0.0, 1.0),
                        minHeight: 10,
                        color: warna,
                        backgroundColor: context.palet.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Label sumbu. Diberi `Expanded` di tengah agar tidak
                    // pernah meluber saat ukuran teks sistem diperbesar.
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
          ],
        ),
      ),
    );
  }
}

class _KartuTidakDikenali extends StatelessWidget {
  const _KartuTidakDikenali({required this.hasil});

  final HasilIdentifikasi hasil;

  static const _panduan = <String>[
    'Ambil dari jarak 15-25 cm sehingga seluruh daun masuk bidang gambar.',
    'Pastikan pencahayaan cukup dan tidak ada bayangan tajam.',
    'Hindari latar yang ramai atau daun lain yang ikut terpotret.',
    'Fokuskan kamera pada bagian yang menunjukkan gejala.',
  ];

  @override
  Widget build(BuildContext context) {
    final warna = context.palet.warning;

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
              'Tingkat keyakinan model hanya '
              '${hasil.keyakinanPersen.toStringAsFixed(2)}%. Sistem tidak '
              'menampilkan diagnosis agar tidak menyesatkan.',
              style: context.teks.bodyMedium,
            ),
            const Divider(height: AppSpacing.lg),
            Text('Coba ambil ulang foto', style: context.teks.titleSmall),
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
                    Expanded(child: Text(p, style: context.teks.bodyMedium)),
                  ],
                ),
              ),
          ],
        ),
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
      judul: 'Probabilitas setiap kelas',
      ikon: Icons.bar_chart_rounded,
      anak: Column(
        children: [
          for (final p in daftar)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
              child: Semantics(
                label: '${p.idPenyakit}, ${p.persen.toStringAsFixed(2)} persen',
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.idPenyakit,
                              style: context.teks.bodySmall?.copyWith(
                                fontWeight: p.idPenyakit == terpilih
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: p.idPenyakit == terpilih
                                    ? context.palet.foreground
                                    : context.palet.mutedForeground,
                              ),
                            ),
                          ),
                          Text(
                            '${p.persen.toStringAsFixed(2)}%',
                            style: context.teks.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
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
            'Semua batang memakai skala absolut 0–100%.',
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
      judul: 'Catatan teknis',
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
            'Hasil identifikasi bersifat bantuan awal, bukan pengganti '
            'pemeriksaan penyuluh pertanian atau laboratorium.',
            style: context.teks.bodySmall,
          ),
        ],
      ),
    );
  }
}
