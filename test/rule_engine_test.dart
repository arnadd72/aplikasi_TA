import 'package:flutter_test/flutter_test.dart';
import 'package:padi_scan/logic/rule_engine.dart';

/// Pengujian unit mesin aturan (Tabel 3.7).
/// R1-R4 memetakan kelas ke rekomendasi bila keyakinan >= 70%.
/// R5 mengembalikan pesan "tidak dikenali" bila keyakinan < 70%.
void main() {
  group('RuleEngine', () {
    test('Label model asing ditolak sebagai galat kontrak', () {
      expect(
        () => RuleEngine.evaluasi(
          idPenyakit: 'kelas_tidak_terdaftar',
          keyakinan: 0.95,
        ),
        throwsStateError,
      );
    });

    test('R1 aktif untuk kelas blas dengan keyakinan 70%', () {
      final k = RuleEngine.evaluasi(idPenyakit: 'blas', keyakinan: 0.70);
      expect(k.aturan, 'R1');
      expect(k.tidakDikenali, isFalse);
    });

    test('R2 aktif untuk kelas hawar daun bakteri', () {
      final k = RuleEngine.evaluasi(
        idPenyakit: 'hawar_daun_bakteri',
        keyakinan: 0.88,
      );
      expect(k.aturan, 'R2');
      expect(k.tidakDikenali, isFalse);
    });

    test('R3 aktif untuk kelas bercak cokelat', () {
      final k = RuleEngine.evaluasi(
        idPenyakit: 'bercak_cokelat',
        keyakinan: 0.95,
      );
      expect(k.aturan, 'R3');
      expect(k.tidakDikenali, isFalse);
    });

    test('R4 aktif untuk daun sehat', () {
      final k = RuleEngine.evaluasi(idPenyakit: 'normal', keyakinan: 0.99);
      expect(k.aturan, 'R4');
      expect(k.tidakDikenali, isFalse);
      expect(k.pesan.toLowerCase(), contains('sehat'));
    });

    test('R5 aktif bila keyakinan di bawah ambang batas', () {
      final k = RuleEngine.evaluasi(idPenyakit: 'blas', keyakinan: 0.69);
      expect(k.aturan, 'R5');
      expect(k.tidakDikenali, isTrue);
      expect(k.pesan.toLowerCase(), contains('tidak dikenali'));
    });

    test('Batas tepat 70% dianggap dikenali', () {
      final k = RuleEngine.evaluasi(idPenyakit: 'blas', keyakinan: 0.70);
      expect(k.tidakDikenali, isFalse);
    });

    test('Ambang batas sesuai rancangan Tabel 3.7', () {
      expect(RuleEngine.ambangKeyakinan, 0.70);
    });
  });
}
