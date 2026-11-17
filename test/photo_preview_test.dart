import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padi_scan/logic/photo_quality_checker.dart';
import 'package:padi_scan/screens/photo_preview_screen.dart';
import 'package:padi_scan/theme/app_theme.dart';

void main() {
  testWidgets('preview memperingatkan foto gelap sebelum konfirmasi', (
    tester,
  ) async {
    var dikonfirmasi = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.terang,
        home: PhotoPreviewScreen(
          pathFoto: 'uji.jpg',
          kualitasAwal: const KualitasFoto(
            terlaluGelap: true,
            buram: false,
            kecerahanRataRata: 20,
            skorKetajaman: 500,
          ),
          pratinjau: const ColoredBox(color: Colors.black),
          onKonfirmasi: () async => dikonfirmasi = true,
        ),
      ),
    );

    expect(find.text('Periksa foto'), findsOneWidget);
    expect(find.text('Foto terlalu gelap'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Gunakan foto'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Foto ulang'), findsOneWidget);

    await tester.tap(find.text('Gunakan foto'));
    await tester.pumpAndSettle();
    expect(dikonfirmasi, isTrue);
  });
}
