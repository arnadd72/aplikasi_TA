import 'package:flutter_test/flutter_test.dart';
import 'package:padi_scan/logic/tflite_classifier.dart';

void main() {
  const labels = ['bercak_cokelat', 'blas', 'hawar_daun_bakteri', 'normal'];

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
