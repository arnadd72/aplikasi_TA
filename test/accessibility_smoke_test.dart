import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padi_scan/screens/app_shell.dart';
import 'package:padi_scan/logic/photo_quality_checker.dart';
import 'package:padi_scan/screens/photo_preview_screen.dart';
import 'package:padi_scan/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('manifest model menyatakan artefak replikasi dan hash tetap', () async {
    final raw = await rootBundle.loadString(
      'assets/models/model_manifest.json',
    );
    final data = jsonDecode(raw) as Map<String, dynamic>;

    expect(data['arsitektur'], 'MobileNetV2');
    expect(data['asal_artefak'], 'reimplementasi_lokal');
    expect(data['setara_artefak_penulis'], isFalse);
    expect(
      data['sha256_model'],
      '55c2517cdd10295a7407ded8ebb8eb2e2ac2fd3c4928f703da39d26aab554bc2',
    );
  });

  testWidgets('shell memenuhi target sentuh Android', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.terang,
        home: const AppShell(
          halaman: [SizedBox(), SizedBox(), SizedBox(), SizedBox()],
        ),
      ),
    );
    await tester.pump();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    expect(tester.takeException(), isNull);
  });

  testWidgets('preview produksi aman pada 320 dp dan teks 200 persen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.gelap,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const PhotoPreviewScreen(
          pathFoto: 'uji.jpg',
          kualitasAwal: KualitasFoto(
            terlaluGelap: true,
            buram: true,
            kecerahanRataRata: 20,
            skorKetajaman: 10,
          ),
          pratinjau: ColoredBox(color: Colors.black),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
