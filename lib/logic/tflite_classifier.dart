import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/hasil_identifikasi.dart';
import 'image_preprocessor.dart';
import 'rule_engine.dart';

/// Menjalankan model TensorFlow Lite di perangkat (F-03, NF-01).
///
/// Berkas model diletakkan di `assets/models/padi_mobilenetv2.tflite`
/// beserta `assets/models/labels.txt` berisi urutan kelas keluaran model.
class TfliteClassifier {
  static const String pathModel = 'assets/models/padi_mobilenetv2.tflite';
  static const String pathLabel = 'assets/models/labels.txt';
  static const String versiModel = 'mobilenetv2-local-replikasi-v1';

  Interpreter? _interpreter;
  List<String> _labels = const [];

  bool get siap => _interpreter != null && _labels.isNotEmpty;
  List<String> get labels => List.unmodifiable(_labels);

  /// Memuat model dan label. Mengembalikan false bila berkas model belum
  /// tersedia sehingga aplikasi tetap dapat dibuka.
  Future<bool> muat() async {
    if (siap) return true;
    try {
      _labels = await _muatLabel();
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(pathModel, options: options);
      final input = _interpreter!.getInputTensor(0);
      final output = _interpreter!.getOutputTensor(0);
      validasiKontrak(
        labels: _labels,
        inputShape: input.shape,
        outputShape: output.shape,
      );
      if (input.type != TensorType.float32 ||
          output.type != TensorType.float32) {
        throw StateError(
          'Kontrak dtype model tidak cocok: ${input.type} → ${output.type}',
        );
      }
      debugPrint(
        '[TFLite] model dimuat. '
        'input=${_interpreter!.getInputTensor(0).shape} '
        'output=${_interpreter!.getOutputTensor(0).shape}',
      );
      return true;
    } on Object catch (e) {
      debugPrint('[TFLite] gagal memuat model: $e');
      _interpreter = null;
      return false;
    }
  }

  static void validasiKontrak({
    required List<String> labels,
    required List<int> inputShape,
    required List<int> outputShape,
  }) {
    const labelWajib = [
      'bercak_cokelat',
      'blas',
      'hawar_daun_bakteri',
      'normal',
    ];
    if (!listEquals(labels, labelWajib)) {
      throw StateError('Urutan atau isi label model tidak sesuai kontrak.');
    }
    if (!listEquals(inputShape, const [1, 224, 224, 3])) {
      throw StateError('Shape input model tidak sesuai kontrak: $inputShape');
    }
    if (!listEquals(outputShape, const [1, 4])) {
      throw StateError('Shape output model tidak sesuai kontrak: $outputShape');
    }
  }

  Future<List<String>> _muatLabel() async {
    final raw = await rootBundle.loadString(pathLabel);
    return raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && !e.startsWith('#'))
        .toList();
  }

  /// Menjalankan inferensi untuk satu berkas citra.
  Future<HasilIdentifikasi> identifikasi(String pathFoto) async {
    if (!siap) {
      final ok = await muat();
      if (!ok) {
        throw StateError(
          'Model TensorFlow Lite belum tersedia di $pathModel. '
          'Letakkan berkas model MobileNetV2 hasil konversi pada folder tersebut.',
        );
      }
    }

    final swTotal = Stopwatch()..start();
    final bytes = await File(pathFoto).readAsBytes();

    // Prapemrosesan: resize 224x224 + rescale 1/255.
    final swPraproses = Stopwatch()..start();
    final masukan = ImagePreprocessor.dariBytes(bytes);
    swPraproses.stop();

    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final jumlahKelas = outputShape.last;
    final keluaran = List.generate(1, (_) => List.filled(jumlahKelas, 0.0));

    final swInferensi = Stopwatch()..start();
    _interpreter!.run(masukan, keluaran);
    swInferensi.stop();

    final nilai = (keluaran.first as List)
        .map((e) => (e as num).toDouble())
        .toList();

    // Urutan label mengikuti labels.txt; jika tidak cocok, pakai indeks.
    final labelAktif = _labels.length == nilai.length
        ? _labels
        : List.generate(nilai.length, (i) => 'kelas_$i');

    final probabilitas = <ProbabilitasKelas>[];
    for (int i = 0; i < nilai.length; i++) {
      probabilitas.add(
        ProbabilitasKelas(idPenyakit: labelAktif[i], nilai: nilai[i]),
      );
    }
    probabilitas.sort((a, b) => b.nilai.compareTo(a.nilai));

    final teratas = probabilitas.first;
    final keputusan = RuleEngine.evaluasi(
      idPenyakit: teratas.idPenyakit,
      keyakinan: teratas.nilai,
    );

    swTotal.stop();

    debugPrint(
      '[TFLite] inferensi ${swInferensi.elapsedMilliseconds} ms | '
      '${teratas.idPenyakit} ${(teratas.nilai * 100).toStringAsFixed(2)}% | '
      'aturan ${keputusan.aturan}',
    );

    return HasilIdentifikasi(
      idPenyakit: teratas.idPenyakit,
      keyakinan: teratas.nilai,
      semuaProbabilitas: probabilitas,
      tidakDikenali: keputusan.tidakDikenali,
      waktuInferensiMs: swInferensi.elapsedMilliseconds,
      waktuPraprosesMs: swPraproses.elapsedMilliseconds,
      waktuTotalMs: swTotal.elapsedMilliseconds,
      aturan: keputusan.aturan,
      pathFoto: pathFoto,
      waktu: DateTime.now(),
    );
  }

  /// Menjalankan inferensi pada banyak citra untuk menghitung akurasi
  /// setelah model diintegrasikan (pengujian akurasi, 928 citra uji).
  Future<List<HasilIdentifikasi>> identifikasiBatch(List<String> paths) async {
    final hasil = <HasilIdentifikasi>[];
    for (final p in paths) {
      hasil.add(await identifikasi(p));
    }
    return hasil;
  }

  /// Rata-rata waktu inferensi (NF-02).
  static double rataRataMs(List<HasilIdentifikasi> hasil) {
    if (hasil.isEmpty) return 0;
    final total = hasil.fold<int>(0, (a, b) => a + b.waktuInferensiMs);
    return total / hasil.length;
  }

  /// Persentil ke-95 waktu inferensi, untuk pelaporan kinerja.
  static double persentilMs(List<HasilIdentifikasi> hasil, double persen) {
    if (hasil.isEmpty) return 0;
    final nilai = hasil.map((e) => e.waktuInferensiMs).toList()..sort();
    final idx = ((persen / 100) * nilai.length).ceil() - 1;
    return nilai[math.min(math.max(idx, 0), nilai.length - 1)].toDouble();
  }

  void tutup() {
    _interpreter?.close();
    _interpreter = null;
  }
}
