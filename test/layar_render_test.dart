import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padi_scan/models/hasil_identifikasi.dart';
import 'package:padi_scan/models/penyakit.dart';
import 'package:padi_scan/screens/detail_riwayat_screen.dart';
import 'package:padi_scan/screens/hasil_screen.dart';
import 'package:padi_scan/screens/informasi_screen.dart';
import 'package:padi_scan/screens/onboarding_screen.dart';
import 'package:padi_scan/screens/panduan_foto_screen.dart';
import 'package:padi_scan/screens/pengaturan_screen.dart';
import 'package:padi_scan/screens/rekomendasi_screen.dart';
import 'package:padi_scan/screens/riwayat_screen.dart';
import 'package:padi_scan/screens/statistik_screen.dart';
import 'package:padi_scan/theme/app_theme.dart';

/// Pengujian render seluruh layar pada mode terang dan gelap.
void main() {
  const penyakitUji = Penyakit(
    idPenyakit: 'blas',
    labelModel: 'Leaf Blast',
    nama: 'Blas (Blas Daun)',
    namaLatin: 'Pyricularia oryzae',
    penyebab: 'Jamur Pyricularia oryzae',
    gejala: 'Bercak belah ketupat pada daun.',
    rekomendasi: [
      Rekomendasi(
        idPenyakit: 'blas',
        kategori: KategoriRekomendasi.kulturTeknis,
        isi: 'Gunakan varietas tahan.',
        sumber: 'BPTP Gorontalo (2016)',
      ),
      Rekomendasi(
        idPenyakit: 'blas',
        kategori: KategoriRekomendasi.kimia,
        isi: 'Perlakuan benih dengan fungisida berbahan aktif trisiklazol.',
        sumber: 'BPTP Gorontalo (2016)',
      ),
    ],
  );

  final hasilUji = HasilIdentifikasi(
    idPenyakit: 'blas',
    keyakinan: 0.94,
    semuaProbabilitas: const [
      ProbabilitasKelas(idPenyakit: 'blas', nilai: 0.94),
      ProbabilitasKelas(idPenyakit: 'bercak_cokelat', nilai: 0.03),
      ProbabilitasKelas(idPenyakit: 'hawar_daun_bakteri', nilai: 0.02),
      ProbabilitasKelas(idPenyakit: 'normal', nilai: 0.01),
    ],
    tidakDikenali: false,
    waktuInferensiMs: 210,
    pathFoto: r'D:\tidak-ada\foto.jpg',
    waktu: DateTime(2026, 11, 16, 9, 5),
  );

  final hasilRagu = HasilIdentifikasi(
    idPenyakit: 'blas',
    keyakinan: 0.62,
    semuaProbabilitas: const [
      ProbabilitasKelas(idPenyakit: 'blas', nilai: 0.62),
      ProbabilitasKelas(idPenyakit: 'normal', nilai: 0.38),
    ],
    tidakDikenali: true,
    waktuInferensiMs: 205,
    pathFoto: r'D:\tidak-ada\foto.jpg',
    waktu: DateTime(2026, 11, 16, 9, 5),
  );

  Future<void> pump(WidgetTester tester, Widget layar, ThemeData tema) async {
    tester.view.physicalSize = const Size(1080, 2263);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: tema, home: layar));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> gulirKe(WidgetTester tester, String teks) async {
    await tester.scrollUntilVisible(
      find.text(teks),
      240,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 60,
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  for (final (nama, tema) in <(String, ThemeData)>[
    ('terang', AppTheme.terang),
    ('gelap', AppTheme.gelap),
  ]) {
    testWidgets('Onboarding ($nama) menggambar tanpa galat tata letak', (
      WidgetTester tester,
    ) async {
      await pump(tester, const OnboardingScreen(), tema);
      expect(tester.takeException(), isNull);
      expect(find.text('Kenali penyakit daun padi'), findsOneWidget);
    });

    testWidgets('Rekomendasi ($nama) menggambar tanpa galat tata letak', (
      WidgetTester tester,
    ) async {
      await pump(tester, const RekomendasiScreen(penyakit: penyakitUji), tema);

      expect(tester.takeException(), isNull);
      expect(find.text('Rekomendasi Penanganan'), findsOneWidget);
      expect(find.text('Blas (Blas Daun)'), findsOneWidget);

      await gulirKe(tester, 'Kultur Teknis dan Pencegahan');
      expect(tester.takeException(), isNull);
      expect(find.text('Gunakan varietas tahan.'), findsOneWidget);

      await gulirKe(tester, 'Pengendalian Kimia');
      expect(tester.takeException(), isNull);
      expect(find.textContaining('trisiklazol'), findsOneWidget);
    });

    testWidgets('Hasil dikenali ($nama) menggambar tanpa galat tata letak', (
      WidgetTester tester,
    ) async {
      await pump(tester, HasilScreen(hasil: hasilUji), tema);

      expect(tester.takeException(), isNull);
      expect(find.text('Hasil Identifikasi'), findsOneWidget);

      await gulirKe(tester, 'Identifikasi Foto Lain');
      expect(tester.takeException(), isNull);
      expect(find.text('Identifikasi Foto Lain'), findsOneWidget);
      expect(find.textContaining('94'), findsWidgets);
    });

    testWidgets('Hasil tidak dikenali ($nama) menampilkan panduan foto ulang', (
      WidgetTester tester,
    ) async {
      await pump(tester, HasilScreen(hasil: hasilRagu), tema);

      expect(tester.takeException(), isNull);
      expect(find.text('Hasil Identifikasi'), findsOneWidget);
      expect(
        find.text(
          'Hasil belum cukup meyakinkan. Coba ambil foto daun yang lebih jelas.',
        ),
        findsOneWidget,
      );

      await gulirKe(tester, 'Identifikasi Foto Lain');
      expect(tester.takeException(), isNull);
      expect(find.text('Identifikasi Foto Lain'), findsOneWidget);
    });

    testWidgets('Riwayat kosong ($nama) menggambar tanpa galat tata letak', (
      WidgetTester tester,
    ) async {
      await pump(tester, const RiwayatScreen(), tema);
      expect(tester.takeException(), isNull);
      expect(find.text('Riwayat Identifikasi'), findsOneWidget);
    });

    testWidgets('Informasi ($nama) menggambar tanpa galat tata letak', (
      WidgetTester tester,
    ) async {
      await pump(tester, const InformasiScreen(), tema);
      expect(tester.takeException(), isNull);
      expect(find.text('Informasi Penyakit'), findsOneWidget);
    });

    testWidgets('Detail riwayat ($nama) menggambar tanpa galat tata letak', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        DetailRiwayatScreen(
          riwayat: Riwayat(
            idRiwayat: 1,
            pathFoto: r'D:\tidak-ada\foto.jpg',
            idPenyakit: 'blas',
            keyakinan: 0.94,
            waktu: DateTime(2026, 11, 16, 9, 5),
          ),
        ),
        tema,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Detail Riwayat'), findsOneWidget);
    });

    testWidgets('Panduan foto ($nama) menggambar tanpa galat tata letak', (
      WidgetTester tester,
    ) async {
      await pump(tester, const PanduanFotoScreen(), tema);

      expect(tester.takeException(), isNull);
      expect(find.text('Panduan Ambil Foto'), findsOneWidget);
    });

    testWidgets('Statistik ($nama) menggambar tanpa galat tata letak', (
      WidgetTester tester,
    ) async {
      await pump(tester, const StatistikScreen(), tema);

      expect(tester.takeException(), isNull);
      expect(find.text('Statistik'), findsOneWidget);
    });

    testWidgets('Pengaturan ($nama) menggambar tanpa galat tata letak', (
      WidgetTester tester,
    ) async {
      await pump(tester, const PengaturanScreen(), tema);

      expect(tester.takeException(), isNull);
      expect(find.text('Pengaturan'), findsOneWidget);
      expect(find.text('Ekspor Riwayat (CSV)'), findsOneWidget);
      expect(find.text('Salin Ringkasan'), findsOneWidget);
    });
  }
}
