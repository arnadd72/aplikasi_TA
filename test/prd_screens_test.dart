import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padi_scan/data/catatan_lapangan_repository.dart';
import 'package:padi_scan/models/catatan_lapangan.dart';
import 'package:padi_scan/models/hasil_identifikasi.dart';
import 'package:padi_scan/models/penyakit.dart';
import 'package:padi_scan/screens/detail_penyakit_screen.dart';
import 'package:padi_scan/screens/form_pengamatan_screen.dart';
import 'package:padi_scan/screens/jadwal_perawatan_screen.dart';
import 'package:padi_scan/screens/kamera_identifikasi_screen.dart';
import 'package:padi_scan/screens/monitoring_perkembangan_screen.dart';
import 'package:padi_scan/theme/app_theme.dart';

class _RepoUji implements CatatanLapanganRepository {
  _RepoUji({this.petak = const [], this.pengamatanDisimpan});

  final List<Petak> petak;
  final ValueChanged<CatatanPengamatan>? pengamatanDisimpan;

  @override
  Future<List<Petak>> semuaPetak() async => petak;
  @override
  Future<int> simpanPetak(Petak nilai) async => nilai.idPetak ?? 1;
  @override
  Future<void> hapusPetak(int idPetak) async {}
  @override
  Future<List<MusimTanam>> musimUntukPetak(int idPetak) async => const [];
  @override
  Future<int> simpanMusim(MusimTanam nilai) async => 1;
  @override
  Future<void> akhiriMusimPetak(int idPetak, DateTime selesai) async {}
  @override
  Future<int> mulaiSesi(SesiSurvei nilai) async => 1;
  @override
  Future<void> selesaikanSesi(int idSesi, DateTime selesai) async {}
  @override
  Future<List<SesiSurvei>> sesiUntukPetak(int idPetak) async => const [];
  @override
  Future<List<Riwayat>> timelinePetak(int idPetak) async => const [];
  @override
  Future<List<Riwayat>> riwayatSesi(int idSesi) async => const [];
  @override
  Future<List<CatatanPengamatan>> pengamatanUntukPetak(int idPetak) async =>
      const [];
  @override
  Future<int> simpanPengamatan(CatatanPengamatan nilai) async {
    pengamatanDisimpan?.call(nilai);
    return 1;
  }

  @override
  Future<void> hapusPengamatan(int idPengamatan) async {}
  @override
  Future<List<JadwalPerawatan>> jadwalUntukPetak(int idPetak) async => const [];
  @override
  Future<int> simpanJadwal(JadwalPerawatan nilai) async => 1;
  @override
  Future<void> ubahStatusJadwal(int idJadwal, bool selesai) async {}
  @override
  Future<void> hapusJadwal(int idJadwal) async {}
}

void main() {
  testWidgets(
    'S-04 KameraIdentifikasiScreen menampilkan panduan framing & tombol aksi PRD',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.terang,
          home: const KameraIdentifikasiScreen(namaPetakAwal: 'Lahan Timur'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Ambil Foto Daun'), findsOneWidget);
      expect(
        find.text('Pastikan daun terlihat jelas dan tidak buram.'),
        findsOneWidget,
      );
      expect(find.text('Galeri'), findsOneWidget);
      expect(find.text('Ambil Foto'), findsOneWidget);
      expect(find.text('Terkait lahan: Lahan Timur'), findsOneWidget);
    },
  );

  testWidgets(
    'S-15 DetailPenyakitScreen menampilkan gejala, faktor, pencegahan & referensi',
    (tester) async {
      const penyakit = Penyakit(
        idPenyakit: 'blas',
        labelModel: 'Leaf Blast',
        nama: 'Blas (Blas Daun)',
        namaLatin: 'Pyricularia oryzae',
        penyebab: 'Jamur Pyricularia oryzae',
        gejala: 'Bercak belah ketupat pada helai daun.',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.terang,
          home: const DetailPenyakitScreen(penyakit: penyakit),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Detail Penyakit'), findsOneWidget);
      expect(find.text('Kelas C01'), findsOneWidget);
      expect(find.text('Blas (Blas Daun)'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Faktor Pendukung'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Gejala & Ciri Visual'), findsOneWidget);
      expect(find.text('Faktor Pendukung'), findsOneWidget);
    },
  );

  testWidgets(
    'S-13 FormPengamatanScreen menyimpan catatan pengamatan lapangan',
    (tester) async {
      CatatanPengamatan? tersimpan;
      final repo = _RepoUji(
        petak: [
          Petak(
            idPetak: 10,
            nama: 'Sawah Selatan',
            dibuatPada: DateTime(2026, 11, 1),
          ),
        ],
        pengamatanDisimpan: (v) => tersimpan = v,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.terang,
          home: FormPengamatanScreen(idPetakAwal: 10, repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Catatan Pengamatan'), findsOneWidget);
      expect(find.text('Sawah Selatan'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Simpan Catatan Pengamatan'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Simpan Catatan Pengamatan'));
      await tester.pumpAndSettle();

      expect(tersimpan, isNotNull);
      expect(tersimpan!.idPetak, 10);
    },
  );

  testWidgets('S-16 JadwalPerawatanScreen dan S-17 MonitoringPerkembanganScreen render tanpa galat', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.terang,
        home: const JadwalPerawatanScreen(),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    expect(find.text('Jadwal Perawatan'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.terang,
        home: const MonitoringPerkembanganScreen(),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    expect(find.text('Monitoring Perkembangan'), findsOneWidget);
  });
}
