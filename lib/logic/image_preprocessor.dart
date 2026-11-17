import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Prapemrosesan citra agar sesuai kondisi saat model dilatih
/// (subbab 2.2.4 dan langkah 3 tahap implementasi):
///  - ubah ukuran menjadi 224 x 224 piksel
///  - normalisasi nilai piksel ke rentang 0-1 (rescale 1/255)
class ImagePreprocessor {
  /// Sisi citra masukan model MobileNetV2.
  static const int ukuranMasukan = 224;

  /// Mengembalikan citra sebagai List 4 dimensi [1][224][224][3]
  /// berisi nilai 0..1, siap dipakai sebagai masukan interpreter.
  static Future<List<List<List<List<double>>>>> dariBerkas(
    String path, {
    int ukuran = ukuranMasukan,
  }) async {
    final bytes = await File(path).readAsBytes();
    return dariBytes(bytes, ukuran: ukuran);
  }

  static List<List<List<List<double>>>> dariBytes(
    Uint8List bytes, {
    int ukuran = ukuranMasukan,
  }) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('Berkas citra tidak dapat dibaca.');
    }

    // MobileNetV2 dilatih pada citra RGB. Pastikan kanal RGB.
    final rgb = decoded.numChannels == 3
        ? decoded
        : decoded.convert(numChannels: 3);

    // Interpolasi bilinear seperti default ImageDataGenerator (target_size).
    final resized = img.copyResize(
      rgb,
      width: ukuran,
      height: ukuran,
      interpolation: img.Interpolation.linear,
    );

    final hasil = <List<List<List<double>>>>[];
    final baris = <List<List<double>>>[];
    for (int y = 0; y < ukuran; y++) {
      final kolom = <List<double>>[];
      for (int x = 0; x < ukuran; x++) {
        final piksel = resized.getPixel(x, y);
        kolom.add([piksel.r / 255.0, piksel.g / 255.0, piksel.b / 255.0]);
      }
      baris.add(kolom);
    }
    hasil.add(baris);
    return hasil;
  }

  /// Versi datar untuk menjaga kinerja pada perangkat kelas bawah.
  /// Digunakan bila tensor masukan berbentuk [1, 224, 224, 3] dan
  /// interpreter menerima data datar.
  static Float32List dariBytesDatar(
    Uint8List bytes, {
    int ukuran = ukuranMasukan,
  }) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('Berkas citra tidak dapat dibaca.');
    }
    final rgb = decoded.numChannels == 3
        ? decoded
        : decoded.convert(numChannels: 3);
    final resized = img.copyResize(
      rgb,
      width: ukuran,
      height: ukuran,
      interpolation: img.Interpolation.linear,
    );

    final out = Float32List(ukuran * ukuran * 3);
    var i = 0;
    for (int y = 0; y < ukuran; y++) {
      for (int x = 0; x < ukuran; x++) {
        final piksel = resized.getPixel(x, y);
        out[i++] = piksel.r / 255.0;
        out[i++] = piksel.g / 255.0;
        out[i++] = piksel.b / 255.0;
      }
    }
    debugPrint(
      '[Preprocess] ${bytes.length} bytes -> ${ukuran}x$ukuran '
      '(${out.length} nilai ternormalisasi)',
    );
    return out;
  }
}
