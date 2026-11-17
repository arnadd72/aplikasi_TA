import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padi_scan/screens/app_shell.dart';
import 'package:padi_scan/theme/app_theme.dart';

void main() {
  testWidgets(
    'shell menampilkan empat tujuan navigasi sesuai PRD Bagian 5.1',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.terang,
          home: AppShell(
            halaman: const [
              Center(child: Text('Isi Beranda')),
              Center(child: Text('Isi Lahan Saya')),
              Center(child: Text('Isi Riwayat')),
              Center(child: Text('Isi Panduan')),
            ],
          ),
        ),
      );

      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Lahan Saya'), findsOneWidget);
      expect(find.text('Riwayat'), findsOneWidget);
      expect(find.text('Panduan'), findsOneWidget);
      expect(find.text('Isi Beranda'), findsOneWidget);

      await tester.tap(find.text('Lahan Saya'));
      await tester.pumpAndSettle();
      expect(find.text('Isi Lahan Saya'), findsOneWidget);

      await tester.tap(find.text('Riwayat'));
      await tester.pumpAndSettle();
      expect(find.text('Isi Riwayat'), findsOneWidget);

      await tester.tap(find.text('Panduan'));
      await tester.pumpAndSettle();
      expect(find.text('Isi Panduan'), findsOneWidget);
    },
  );

  testWidgets('shell tidak overflow pada lebar 320 dp', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.terang,
        home: AppShell(
          halaman: const [SizedBox(), SizedBox(), SizedBox(), SizedBox()],
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
