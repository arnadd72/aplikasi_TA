import '../models/catatan_lapangan.dart';
import '../models/hasil_identifikasi.dart';
import 'database_helper.dart';

abstract interface class CatatanLapanganRepository {
  Future<List<Petak>> semuaPetak();
  Future<int> simpanPetak(Petak nilai);
  Future<void> hapusPetak(int idPetak);
  Future<List<MusimTanam>> musimUntukPetak(int idPetak);
  Future<int> simpanMusim(MusimTanam nilai);
  Future<void> akhiriMusimPetak(int idPetak, DateTime selesai);
  Future<int> mulaiSesi(SesiSurvei nilai);
  Future<void> selesaikanSesi(int idSesi, DateTime selesai);
  Future<List<SesiSurvei>> sesiUntukPetak(int idPetak);
  Future<List<Riwayat>> timelinePetak(int idPetak);
  Future<List<Riwayat>> riwayatSesi(int idSesi);
  Future<List<CatatanPengamatan>> pengamatanUntukPetak(int idPetak);
  Future<int> simpanPengamatan(CatatanPengamatan nilai);
  Future<void> hapusPengamatan(int idPengamatan);
  Future<List<JadwalPerawatan>> jadwalUntukPetak(int idPetak);
  Future<int> simpanJadwal(JadwalPerawatan nilai);
  Future<void> ubahStatusJadwal(int idJadwal, bool selesai);
  Future<void> hapusJadwal(int idJadwal);
}

class DatabaseCatatanLapanganRepository implements CatatanLapanganRepository {
  const DatabaseCatatanLapanganRepository();

  DatabaseHelper get _db => DatabaseHelper.instance;

  @override
  Future<List<Petak>> semuaPetak() => _db.semuaPetak();
  @override
  Future<int> simpanPetak(Petak nilai) => _db.simpanPetak(nilai);
  @override
  Future<void> hapusPetak(int idPetak) => _db.hapusPetak(idPetak);
  @override
  Future<List<MusimTanam>> musimUntukPetak(int idPetak) =>
      _db.musimUntukPetak(idPetak);
  @override
  Future<int> simpanMusim(MusimTanam nilai) => _db.simpanMusim(nilai);
  @override
  Future<void> akhiriMusimPetak(int idPetak, DateTime selesai) =>
      _db.akhiriMusimPetak(idPetak, selesai);
  @override
  Future<int> mulaiSesi(SesiSurvei nilai) => _db.mulaiSesi(nilai);
  @override
  Future<void> selesaikanSesi(int idSesi, DateTime selesai) =>
      _db.selesaikanSesi(idSesi, selesai);
  @override
  Future<List<SesiSurvei>> sesiUntukPetak(int idPetak) =>
      _db.sesiUntukPetak(idPetak);
  @override
  Future<List<Riwayat>> timelinePetak(int idPetak) =>
      _db.timelinePetak(idPetak);
  @override
  Future<List<Riwayat>> riwayatSesi(int idSesi) => _db.riwayatSesi(idSesi);
  @override
  Future<List<CatatanPengamatan>> pengamatanUntukPetak(int idPetak) =>
      _db.pengamatanUntukPetak(idPetak);
  @override
  Future<int> simpanPengamatan(CatatanPengamatan nilai) =>
      _db.simpanPengamatan(nilai);
  @override
  Future<void> hapusPengamatan(int idPengamatan) =>
      _db.hapusPengamatan(idPengamatan);
  @override
  Future<List<JadwalPerawatan>> jadwalUntukPetak(int idPetak) =>
      _db.jadwalUntukPetak(idPetak);
  @override
  Future<int> simpanJadwal(JadwalPerawatan nilai) => _db.simpanJadwal(nilai);
  @override
  Future<void> ubahStatusJadwal(int idJadwal, bool selesai) =>
      _db.ubahStatusJadwal(idJadwal, selesai);
  @override
  Future<void> hapusJadwal(int idJadwal) => _db.hapusJadwal(idJadwal);
}
