import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padi_scan/models/hasil_identifikasi.dart';
import 'package:padi_scan/screens/hasil_screen.dart';
import 'package:padi_scan/theme/app_theme.dart';

HasilIdentifikasi _hasil({
  String id = 'normal',
  bool tidakDikenali = false,
  List<String> peringatan = const [],
}) => HasilIdentifikasi(
  idPenyakit: id,
  keyakinan: tidakDikenali ? 0.55 : 0.75,
  semuaProbabilitas: [
    ProbabilitasKelas(idPenyakit: id, nilai: tidakDikenali ? 0.55 : 0.75),
    const ProbabilitasKelas(idPenyakit: 'blas', nilai: 0.25),
  ],
  tidakDikenali: tidakDikenali,
  waktuPraprosesMs: 12,
  waktuInferensiMs: 45,
  waktuTotalMs: 80,
  aturan: tidakDikenali ? 'R5' : 'R4',
  peringatanKualitas: peringatan,
  pathFoto: 'tidak-ada.jpg',
  waktu: DateTime(2026, 11, 17),
);

void main() {
  testWidgets('hasil sehat memakai bahasa keputusan yang jelas', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.terang,
        home: HasilScreen(hasil: _hasil()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Daun terdeteksi sehat'), findsOneWidget);
    expect(find.text('Aturan R4'), findsOneWidget);
    expect(find.text('12 ms'), findsOneWidget);
    expect(find.text('45 ms'), findsOneWidget);
    expect(find.text('80 ms'), findsOneWidget);
  });

  testWidgets('hasil tetap menampilkan peringatan kualitas foto', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.terang,
        home: HasilScreen(
          hasil: _hasil(peringatan: const ['Foto berpotensi buram']),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Foto berpotensi buram'), findsOneWidget);
  });

  testWidgets('batang probabilitas memakai skala absolut nol sampai seratus', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.terang,
        home: HasilScreen(hasil: _hasil()),
      ),
    );
    await tester.pumpAndSettle();

    final batang = tester
        .widgetList<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        )
        .toList();
    expect(batang.any((item) => item.value == 0.25), isTrue);
  });
}
