import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padi_scan/data/catatan_lapangan_repository.dart';
import 'package:padi_scan/models/catatan_lapangan.dart';
import 'package:padi_scan/models/hasil_identifikasi.dart';
import 'package:padi_scan/screens/onboarding_screen.dart';
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
  Future<void> hapusPetak(int idPetak) async {}
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
  @override
  Future<List<CatatanPengamatan>> pengamatanUntukPetak(int idPetak) async =>
      const [];
  @override
  Future<int> simpanPengamatan(CatatanPengamatan nilai) async =>
      nilai.idPengamatan ?? 1;
  @override
  Future<void> hapusPengamatan(int idPengamatan) async {}
  @override
  Future<List<JadwalPerawatan>> jadwalUntukPetak(int idPetak) async => const [];
  @override
  Future<int> simpanJadwal(JadwalPerawatan nilai) async => nilai.idJadwal ?? 1;
  @override
  Future<void> ubahStatusJadwal(int idJadwal, bool selesai) async {}
  @override
  Future<void> hapusJadwal(int idJadwal) async {}
}

void main() {
  test('Petak menghitung umur tanaman HST secara deterministik (PRD F-12)', () {
    final tanpaTanggal = Petak(
      nama: 'Lahan A',
      dibuatPada: DateTime(2026, 11, 1),
    );
    expect(tanpaTanggal.umurHariSetelahTanam(), isNull);

    final denganTanggal = Petak(
      nama: 'Lahan B',
      luasHektare: 0.75,
      satuanLuas: 'ha',
      varietas: 'Inpari 32',
      tanggalTanam: DateTime(2026, 10, 1),
      dibuatPada: DateTime(2026, 10, 1),
    );
    expect(
      denganTanggal.umurHariSetelahTanam(sekarang: DateTime(2026, 11, 10)),
      40,
    );
    expect(
      denganTanggal.faseTanam(sekarang: DateTime(2026, 11, 10)),
      'Fase Vegetatif (Anakan)',
    );
    expect(denganTanggal.labelLuas, '0,75 ha');
  });

  testWidgets('Onboarding menampilkan tiga halaman PRD F-01', (tester) async {
    var selesai = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.terang,
        home: OnboardingScreen(onSelesai: () => selesai = true),
      ),
    );
    await tester.pump();

    expect(find.text('Kenali penyakit daun padi'), findsOneWidget);
    expect(
      find.text('Ambil foto daun padi untuk mengetahui kemungkinan penyakitnya.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Dapatkan panduan penanganan'), findsOneWidget);

    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Gunakan tanpa internet'), findsOneWidget);

    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();
    expect(selesai, isTrue);
  });

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
                varietas: 'Inpari 32',
                luasHektare: 0.5,
                satuanLuas: 'ha',
                tanggalTanam: DateTime(2026, 10, 15),
                dibuatPada: DateTime(2026, 11, 17),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Petak Utara'), findsOneWidget);
    expect(find.text('Varietas: Inpari 32'), findsOneWidget);
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
