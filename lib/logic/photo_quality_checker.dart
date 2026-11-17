import 'dart:typed_data';

import 'package:image/image.dart' as img;

class KualitasFoto {
  final bool terlaluGelap;
  final bool buram;
  final double kecerahanRataRata;
  final double skorKetajaman;

  const KualitasFoto({
    required this.terlaluGelap,
    required this.buram,
    required this.kecerahanRataRata,
    required this.skorKetajaman,
  });

  bool get layak => !terlaluGelap && !buram;

  List<String> get peringatan => [
    if (terlaluGelap) 'Foto terlalu gelap',
    if (buram) 'Foto berpotensi buram',
  ];
}

/// Pemeriksaan deterministik, lokal, dan bukan bagian dari diagnosis model.
class PhotoQualityChecker {
  static const double ambangGelap = 45;
  static const double ambangKetajaman = 120;

  static KualitasFoto periksaBytes(Uint8List bytes) {
    final sumber = img.decodeImage(bytes);
    if (sumber == null) {
      throw const FormatException('Berkas bukan citra yang dapat dibaca.');
    }
    final gambar = sumber.width > 128 || sumber.height > 128
        ? img.copyResize(sumber, width: 128, maintainAspect: true)
        : sumber;

    final abu = List.generate(
      gambar.height,
      (y) => List<double>.filled(gambar.width, 0),
    );
    var totalCahaya = 0.0;
    for (var y = 0; y < gambar.height; y++) {
      for (var x = 0; x < gambar.width; x++) {
        final piksel = gambar.getPixel(x, y);
        final nilai = 0.2126 * piksel.r + 0.7152 * piksel.g + 0.0722 * piksel.b;
        abu[y][x] = nilai;
        totalCahaya += nilai;
      }
    }
    final rataCahaya = totalCahaya / (gambar.width * gambar.height);

    final laplacian = <double>[];
    for (var y = 1; y < gambar.height - 1; y++) {
      for (var x = 1; x < gambar.width - 1; x++) {
        laplacian.add(
          4 * abu[y][x] -
              abu[y - 1][x] -
              abu[y + 1][x] -
              abu[y][x - 1] -
              abu[y][x + 1],
        );
      }
    }
    final rataLaplacian = laplacian.isEmpty
        ? 0.0
        : laplacian.reduce((a, b) => a + b) / laplacian.length;
    final variansi = laplacian.isEmpty
        ? 0.0
        : laplacian
                  .map(
                    (nilai) =>
                        (nilai - rataLaplacian) * (nilai - rataLaplacian),
                  )
                  .reduce((a, b) => a + b) /
              laplacian.length;

    return KualitasFoto(
      terlaluGelap: rataCahaya < ambangGelap,
      buram: variansi < ambangKetajaman,
      kecerahanRataRata: rataCahaya,
      skorKetajaman: variansi,
    );
  }
}
