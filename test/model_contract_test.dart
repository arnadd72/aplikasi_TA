import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:padi_scan/logic/image_preprocessor.dart';
import 'package:padi_scan/logic/tflite_classifier.dart';
import 'package:padi_scan/models/penyakit.dart';

void main() {
  const labels = ['bercak_cokelat', 'blas', 'hawar_daun_bakteri', 'normal'];

  test('Penyakit.namaDariId memetakan empat kelas ke Bahasa Indonesia', () {
    expect(Penyakit.namaDariId('bercak_cokelat'), 'Bercak Cokelat');
    expect(Penyakit.namaDariId('blas'), 'Blas (Blas Daun)');
    expect(
      Penyakit.namaDariId('hawar_daun_bakteri'),
      'Hawar Daun Bakteri (HDB)',
    );
    expect(Penyakit.namaDariId('normal'), 'Daun Sehat');
    expect(Penyakit.namaDariId(''), 'Tanpa hasil');
  });

  test('ImagePreprocessor mempertahankan nilai piksel citra 224x224', () {
    final citra = img.Image(width: 224, height: 224);
    img.fill(citra, color: img.ColorRgb8(51, 102, 153));
    final png = Uint8List.fromList(img.encodePng(citra));

    final tensor = ImagePreprocessor.dariBytes(png);
    expect(tensor.length, 1);
    expect(tensor.first.length, 224);
    expect(tensor.first.first.length, 224);
    expect(tensor.first.first.first[0], closeTo(51 / 255.0, 1e-6));
    expect(tensor.first.first.first[1], closeTo(102 / 255.0, 1e-6));
    expect(tensor.first.first.first[2], closeTo(153 / 255.0, 1e-6));
  });

  test('kontrak model menerima urutan label dan shape penelitian', () {
    expect(
      () => TfliteClassifier.validasiKontrak(
        labels: labels,
        inputShape: const [1, 224, 224, 3],
        outputShape: const [1, 4],
      ),
      returnsNormally,
    );
  });

  test('kontrak model menolak label asing walau bukan argmax', () {
    expect(
      () => TfliteClassifier.validasiKontrak(
        labels: const ['asing', 'blas', 'hawar_daun_bakteri', 'normal'],
        inputShape: const [1, 224, 224, 3],
        outputShape: const [1, 4],
      ),
      throwsStateError,
    );
  });

  test('kontrak model menolak shape input berbeda', () {
    expect(
      () => TfliteClassifier.validasiKontrak(
        labels: labels,
        inputShape: const [1, 192, 192, 3],
        outputShape: const [1, 4],
      ),
      throwsStateError,
    );
  });
}
