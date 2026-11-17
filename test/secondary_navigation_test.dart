import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padi_scan/models/hasil_identifikasi.dart';
import 'package:padi_scan/screens/detail_riwayat_screen.dart';
import 'package:padi_scan/theme/app_theme.dart';
import 'package:padi_scan/utils/riwayat_exporter.dart';

void main() {
  final riwayat = Riwayat(
    idRiwayat: 1,
    pathFoto: r'C:\foto\daun.jpg',
    idPenyakit: 'blas',
    keyakinan: 0.9123,
    waktu: DateTime(2026, 11, 17, 9, 15),
    idPetak: 2,
    idMusim: 3,
    idSesi: 4,
    aturan: 'R1',
    waktuPraprosesMs: 11,
    waktuInferensiMs: 52,
    waktuTotalMs: 77,
    fotoGelap: false,
    fotoBuram: true,
    modelVersion: 'model-uji-v1',
  );

  test('CSV v2 memuat audit, relasi lapangan, dan timing', () {
    final csv = RiwayatExporter.buatCsv([riwayat]);

    expect(csv, contains('id_petak;id_musim;id_sesi'));
    expect(csv, contains('2;3;4'));
    expect(csv, contains('R1;11;52;77'));
    expect(csv, contains('model-uji-v1'));
    expect(csv, contains('buram'));
  });

  test('CSV tidak mengarang timing dan kualitas untuk riwayat warisan', () {
    final lama = Riwayat.fromDb({
      'path_foto': 'lama.jpg',
      'id_penyakit': 'normal',
      'keyakinan': 0.9,
      'waktu': '2025-01-01T00:00:00.000',
    });
    final csv = RiwayatExporter.buatCsv([lama]);

    expect(csv, contains('tidak_dicatat'));
    expect(csv, isNot(contains(';0;0;0;baik;')));
  });

  testWidgets('detail riwayat membuka bukti audit model', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.terang,
        home: DetailRiwayatScreen(riwayat: riwayat),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('model-uji-v1'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('model-uji-v1'), findsOneWidget);
    expect(find.text('52 ms'), findsOneWidget);
    expect(find.text('Foto berpotensi buram'), findsOneWidget);
  });
}
