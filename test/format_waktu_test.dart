import 'package:flutter_test/flutter_test.dart';
import 'package:padi_scan/utils/format_waktu.dart';

/// Pengujian pemformatan tanggal dan waktu bahasa Indonesia.
///
/// Dipakai pada layar hasil (F-04) dan riwayat (F-07), sehingga formatnya
/// harus stabil tanpa bergantung pada paket `intl`.
void main() {
  group('FormatWaktu', () {
    final waktu = DateTime(2026, 11, 16, 9, 5);

    test('ringkas memakai singkatan bulan Indonesia', () {
      expect(FormatWaktu.ringkas(waktu), '16 Nov 2026, 09:05');
    });

    test('angka memakai urutan hari/bulan/tahun', () {
      expect(FormatWaktu.angka(waktu), '16/11/2026 09:05');
    });

    test('panjang memakai nama bulan penuh', () {
      expect(FormatWaktu.panjang(waktu), '16 November 2026');
    });

    test('seluruh nama bulan terpetakan', () {
      const diharapkan = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      for (var i = 0; i < 12; i++) {
        final w = DateTime(2026, i + 1, 1);
        expect(FormatWaktu.panjang(w), '1 ${diharapkan[i]} 2026');
      }
    });

    test('relatif mengubah satuan sesuai selang', () {
      final kini = DateTime(2026, 11, 16, 12, 0);
      expect(
        FormatWaktu.relatif(
          kini.subtract(const Duration(seconds: 20)),
          sekarang: kini,
        ),
        'baru saja',
      );
      expect(
        FormatWaktu.relatif(
          kini.subtract(const Duration(minutes: 12)),
          sekarang: kini,
        ),
        '12 menit lalu',
      );
      expect(
        FormatWaktu.relatif(
          kini.subtract(const Duration(hours: 3)),
          sekarang: kini,
        ),
        '3 jam lalu',
      );
      expect(
        FormatWaktu.relatif(
          kini.subtract(const Duration(days: 2)),
          sekarang: kini,
        ),
        '2 hari lalu',
      );
    });

    test('relatif memakai tanggal penuh setelah 30 hari', () {
      final kini = DateTime(2026, 12, 31, 12, 0);
      expect(
        FormatWaktu.relatif(DateTime(2026, 1, 5), sekarang: kini),
        '5 Januari 2026',
      );
    });
  });
}
