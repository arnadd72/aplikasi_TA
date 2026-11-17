import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padi_scan/screens/home_screen.dart';
import 'package:padi_scan/theme/app_theme.dart';

/// Pengujian tata letak Beranda (PRD F-02 & S-03).
void main() {
  Future<void> pumpBeranda(WidgetTester tester, ThemeData tema) async {
    tester.view.physicalSize = const Size(1080, 2263);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: tema, home: const HomeScreen()));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('Beranda terang menggambar tanpa galat tata letak', (
    WidgetTester tester,
  ) async {
    await pumpBeranda(tester, AppTheme.terang);

    expect(tester.takeException(), isNull);
    expect(find.text('Selamat datang'), findsOneWidget);
    expect(
      find.text('Pantau kesehatan tanaman padi Anda.'),
      findsOneWidget,
    );
    expect(find.text('Periksa Kesehatan Daun Padi'), findsOneWidget);
    expect(find.text('Identifikasi Sekarang'), findsOneWidget);
    expect(find.text('Ambil Foto Daun'), findsOneWidget);
    expect(find.text('Pilih dari Galeri'), findsOneWidget);

    final ukuran = tester.getSize(find.byType(Card).first);
    expect(ukuran.height, greaterThan(200));
    expect(ukuran.height.isFinite, isTrue);
  });

  testWidgets('Beranda gelap menggambar tanpa galat tata letak', (
    WidgetTester tester,
  ) async {
    await pumpBeranda(tester, AppTheme.gelap);

    expect(tester.takeException(), isNull);
    expect(find.text('Identifikasi Sekarang'), findsOneWidget);
    expect(find.text('Ambil Foto Daun'), findsOneWidget);
    expect(tester.getSize(find.byType(Card).first).height.isFinite, isTrue);
  });

  testWidgets('Bagian bawah beranda tercapai setelah digulir', (
    WidgetTester tester,
  ) async {
    await pumpBeranda(tester, AppTheme.terang);
    expect(tester.takeException(), isNull);

    await tester.dragUntilVisible(
      find.text('Cara pakai'),
      find.byType(CustomScrollView),
      const Offset(0, -320),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Cara pakai'), findsOneWidget);
    expect(find.text('Buka Pustaka'), findsOneWidget);
    expect(find.text('Info Penyakit'), findsOneWidget);
  });
}
