import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padi_scan/screens/app_shell.dart';
import 'package:padi_scan/theme/app_theme.dart';

void main() {
  testWidgets('shell menampilkan empat tujuan navigasi berbahasa Indonesia', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.terang,
        home: AppShell(
          halaman: const [
            Center(child: Text('Isi Periksa')),
            Center(child: Text('Isi Riwayat')),
            Center(child: Text('Isi Edukasi')),
            Center(child: Text('Isi Pengaturan')),
          ],
        ),
      ),
    );

    expect(find.text('Periksa'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.text('Edukasi'), findsOneWidget);
    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.text('Isi Periksa'), findsOneWidget);

    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();
    expect(find.text('Isi Riwayat'), findsOneWidget);
  });

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
