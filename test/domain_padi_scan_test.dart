import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:padi_scan/logic/photo_quality_checker.dart';
import 'package:padi_scan/models/catatan_lapangan.dart';

void main() {
  group('RingkasanSesi', () {
    test('menghitung jumlah kelas dan hasil tidak pasti secara terpisah', () {
      final ringkasan = RingkasanSesi.dariPengamatan(const [
        PengamatanSurvei(idPenyakit: 'blas', tidakPasti: false),
        PengamatanSurvei(idPenyakit: 'blas', tidakPasti: false),
        PengamatanSurvei(idPenyakit: 'normal', tidakPasti: false),
        PengamatanSurvei(idPenyakit: 'bercak_cokelat', tidakPasti: true),
      ]);

      expect(ringkasan.totalDaun, 4);
      expect(ringkasan.jumlahTidakPasti, 1);
      expect(ringkasan.jumlahPerKelas, {'blas': 2, 'normal': 1});
      expect(ringkasan.kelasDominan, 'blas');
    });

    test('ringkasan kosong tidak memiliki kelas dominan', () {
      final ringkasan = RingkasanSesi.dariPengamatan(const []);

      expect(ringkasan.totalDaun, 0);
      expect(ringkasan.kelasDominan, isNull);
    });
  });

  group('PhotoQualityChecker', () {
    test('menandai foto sangat gelap', () {
      final gambar = img.Image(width: 24, height: 24);
      img.fill(gambar, color: img.ColorRgb8(4, 4, 4));

      final kualitas = PhotoQualityChecker.periksaBytes(
        Uint8List.fromList(img.encodePng(gambar)),
      );

      expect(kualitas.terlaluGelap, isTrue);
    });

    test('membedakan pola tajam dari bidang seragam buram', () {
      final tajam = img.Image(width: 24, height: 24);
      for (var y = 0; y < 24; y++) {
        for (var x = 0; x < 24; x++) {
          final nilai = (x + y).isEven ? 0 : 255;
          tajam.setPixelRgb(x, y, nilai, nilai, nilai);
        }
      }
      final seragam = img.Image(width: 24, height: 24);
      img.fill(seragam, color: img.ColorRgb8(180, 180, 180));

      final kualitasTajam = PhotoQualityChecker.periksaBytes(
        Uint8List.fromList(img.encodePng(tajam)),
      );
      final kualitasSeragam = PhotoQualityChecker.periksaBytes(
        Uint8List.fromList(img.encodePng(seragam)),
      );

      expect(kualitasTajam.buram, isFalse);
      expect(kualitasSeragam.buram, isTrue);
    });
  });
}
