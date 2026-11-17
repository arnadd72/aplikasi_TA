import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padi_scan/screens/home_screen.dart';
import 'package:padi_scan/theme/app_theme.dart';

/// Regresi: `Row` pada `_MenuCepat` sempat memakai
/// `CrossAxisAlignment.stretch` langsung di dalam `SliverList`. Tinggi
/// `SliverList` tidak terbatas sehingga `Row` meminta tinggi `Infinity`,
/// tata letak gagal, dan seluruh isi beranda tidak pernah tergambar.
/// Perbaikan: bungkus dengan `IntrinsicHeight`.
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
    expect(find.text('Padi Scan'), findsOneWidget);
    expect(find.text('Periksa daun padi Anda'), findsOneWidget);
    expect(find.text('Ambil Foto Daun'), findsOneWidget);
    expect(find.text('Pilih dari Galeri'), findsOneWidget);

    // Kartu tindakan utama harus punya tinggi nyata, bukan 0 atau tak hingga.
    final ukuran = tester.getSize(find.byType(Card).first);
    expect(ukuran.height, greaterThan(200));
    expect(ukuran.height.isFinite, isTrue);
  });

  testWidgets('Beranda gelap menggambar tanpa galat tata letak', (
    WidgetTester tester,
  ) async {
    await pumpBeranda(tester, AppTheme.gelap);

    expect(tester.takeException(), isNull);
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
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.text('Info Penyakit'), findsOneWidget);
  });
}
