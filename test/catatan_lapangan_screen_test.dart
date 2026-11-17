import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padi_scan/data/catatan_lapangan_repository.dart';
import 'package:padi_scan/models/catatan_lapangan.dart';
import 'package:padi_scan/models/hasil_identifikasi.dart';
import 'package:padi_scan/screens/petak_screen.dart';
import 'package:padi_scan/screens/sesi_survei_screen.dart';
import 'package:padi_scan/theme/app_theme.dart';

class _RepoPalsu implements CatatanLapanganRepository {
  _RepoPalsu({this.petak = const []});
  final List<Petak> petak;

  @override
  Future<List<Petak>> semuaPetak() async => petak;
  @override
  Future<int> simpanPetak(Petak nilai) async => nilai.idPetak ?? 1;
  @override
  Future<List<MusimTanam>> musimUntukPetak(int idPetak) async => const [];
  @override
  Future<int> simpanMusim(MusimTanam nilai) async => nilai.idMusim ?? 1;
  @override
  Future<void> akhiriMusimPetak(int idPetak, DateTime selesai) async {}
  @override
  Future<int> mulaiSesi(SesiSurvei nilai) async => nilai.idSesi ?? 1;
  @override
  Future<void> selesaikanSesi(int idSesi, DateTime selesai) async {}
  @override
  Future<List<SesiSurvei>> sesiUntukPetak(int idPetak) async => const [];
  @override
  Future<List<Riwayat>> timelinePetak(int idPetak) async => const [];
  @override
  Future<List<Riwayat>> riwayatSesi(int idSesi) async => const [];
}

void main() {
  testWidgets('petak kosong memberi pintu tambah yang jelas', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.terang,
        home: PetakScreen(repository: _RepoPalsu()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada petak'), findsOneWidget);
    expect(find.text('Tambah petak'), findsWidgets);
  });

  testWidgets('petak menampilkan tindakan survei dan timeline', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.terang,
        home: PetakScreen(
          repository: _RepoPalsu(
            petak: [
              Petak(
                idPetak: 3,
                nama: 'Petak Utara',
                lokasiCatatan: 'Dekat saluran air',
                dibuatPada: DateTime(2026, 11, 17),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Petak Utara'), findsOneWidget);
    expect(find.text('Mulai survei'), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);
  });

  testWidgets('sesi survei memperbarui progres banyak daun', (tester) async {
    var urutan = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.terang,
        home: SesiSurveiScreen(
          sesi: SesiSurvei(
            idSesi: 8,
            idPetak: 3,
            mulai: DateTime(2026, 11, 17),
            targetDaun: 3,
          ),
          namaPetak: 'Petak Utara',
          onPeriksa: () async {
            urutan++;
            return PengamatanSurvei(
              idPenyakit: urutan == 1 ? 'blas' : 'normal',
              tidakPasti: false,
            );
          },
          onSelesai: () async {},
          pengamatanAwal: const [
            PengamatanSurvei(idPenyakit: 'normal', tidakPasti: false),
          ],
        ),
      ),
    );

    expect(find.text('1 dari 3 daun'), findsOneWidget);
    await tester.tap(find.text('Periksa daun berikutnya'));
    await tester.pumpAndSettle();
    expect(find.text('2 dari 3 daun'), findsOneWidget);
    expect(find.text('Blas: 1'), findsOneWidget);
  });

  testWidgets('sesi survei menghitung pemeriksaan gagal', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.terang,
        home: SesiSurveiScreen(
          sesi: SesiSurvei(
            idSesi: 9,
            idPetak: 3,
            mulai: DateTime(2026, 11, 17),
          ),
          namaPetak: 'Petak Utara',
          onPeriksa: () async => throw StateError('uji'),
          onSelesai: () async {},
        ),
      ),
    );

    await tester.tap(find.text('Periksa daun berikutnya'));
    await tester.pumpAndSettle();
    expect(find.text('Gagal: 1'), findsOneWidget);
  });
}
