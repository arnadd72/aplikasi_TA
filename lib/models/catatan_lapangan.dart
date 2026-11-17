/// Entitas pengelolaan lahan (`farms`), musim tanam, survei, catatan
/// pengamatan manual (`observations`), dan jadwal perawatan (`schedules`)
/// sesuai PRD Bagian 6 (F-11..F-13), Bagian 7 (F-16..F-18), dan Bagian 13.
class Petak {
  final int? idPetak;
  final String nama;
  final String lokasiCatatan;
  final double? luasHektare;
  final String satuanLuas;
  final String varietas;
  final DateTime? tanggalTanam;
  final String catatan;
  final DateTime dibuatPada;

  const Petak({
    this.idPetak,
    required this.nama,
    this.lokasiCatatan = '',
    this.luasHektare,
    this.satuanLuas = 'ha',
    this.varietas = '',
    this.tanggalTanam,
    this.catatan = '',
    required this.dibuatPada,
  });

  /// Menghitung umur tanaman dalam Hari Setelah Tanam (HST) secara
  /// deterministik dari `tanggalTanam` (PRD F-12).
  /// Jika `tanggalTanam` tidak tersedia, mengembalikan `null`.
  int? umurHariSetelahTanam({DateTime? sekarang}) {
    final tanam = tanggalTanam;
    if (tanam == null) return null;
    final acuan = sekarang ?? DateTime.now();
    final hariAcuan = DateTime(acuan.year, acuan.month, acuan.day);
    final hariTanam = DateTime(tanam.year, tanam.month, tanam.day);
    final selisih = hariAcuan.difference(hariTanam).inDays;
    return selisih < 0 ? 0 : selisih;
  }

  /// Fase budidaya berdasarkan umur HST (informatif non-AI).
  String? faseTanam({DateTime? sekarang}) {
    final hst = umurHariSetelahTanam(sekarang: sekarang);
    if (hst == null) return null;
    if (hst <= 15) return 'Fase Semai / Bibit';
    if (hst <= 45) return 'Fase Vegetatif (Anakan)';
    if (hst <= 75) return 'Fase Generatif (Bunting/Malai)';
    return 'Fase Pemasakan Bulir';
  }

  String? get labelLuas {
    if (luasHektare == null) return null;
    final teksAngka = luasHektare! == luasHektare!.roundToDouble()
        ? luasHektare!.toInt().toString()
        : luasHektare!.toStringAsFixed(2).replaceAll('.', ',');
    return '$teksAngka $satuanLuas';
  }

  factory Petak.fromDb(Map<String, dynamic> row) => Petak(
    idPetak: row['id_petak'] as int?,
    nama: row['nama'] as String,
    lokasiCatatan: (row['lokasi_catatan'] as String?) ?? '',
    luasHektare: (row['luas_hektare'] as num?)?.toDouble(),
    satuanLuas: (row['satuan_luas'] as String?)?.isNotEmpty == true
        ? row['satuan_luas'] as String
        : 'ha',
    varietas: row['varietas'] as String? ?? '',
    tanggalTanam: DateTime.tryParse(row['tanggal_tanam'] as String? ?? ''),
    catatan: (row['catatan'] as String?) ?? '',
    dibuatPada:
        DateTime.tryParse(row['dibuat_pada'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  Map<String, dynamic> toDb() => {
    if (idPetak != null) 'id_petak': idPetak,
    'nama': nama.trim(),
    'lokasi_catatan': lokasiCatatan.trim(),
    'luas_hektare': luasHektare,
    'satuan_luas': satuanLuas.trim().isEmpty ? 'ha' : satuanLuas.trim(),
    'varietas': varietas.trim(),
    'tanggal_tanam': tanggalTanam?.toIso8601String(),
    'catatan': catatan.trim(),
    'dibuat_pada': dibuatPada.toIso8601String(),
  };
}

class MusimTanam {
  final int? idMusim;
  final int idPetak;
  final String nama;
  final DateTime mulai;
  final DateTime? selesai;
  final bool aktif;

  const MusimTanam({
    this.idMusim,
    required this.idPetak,
    required this.nama,
    required this.mulai,
    this.selesai,
    this.aktif = true,
  });

  factory MusimTanam.fromDb(Map<String, dynamic> row) => MusimTanam(
    idMusim: row['id_musim'] as int?,
    idPetak: row['id_petak'] as int,
    nama: row['nama'] as String,
    mulai: DateTime.parse(row['mulai'] as String),
    selesai: DateTime.tryParse(row['selesai'] as String? ?? ''),
    aktif: (row['aktif'] as int? ?? 1) == 1,
  );

  Map<String, dynamic> toDb() => {
    if (idMusim != null) 'id_musim': idMusim,
    'id_petak': idPetak,
    'nama': nama.trim(),
    'mulai': mulai.toIso8601String(),
    'selesai': selesai?.toIso8601String(),
    'aktif': aktif ? 1 : 0,
  };
}

class SesiSurvei {
  final int? idSesi;
  final int idPetak;
  final int? idMusim;
  final DateTime mulai;
  final DateTime? selesai;
  final int targetDaun;
  final String catatan;

  const SesiSurvei({
    this.idSesi,
    required this.idPetak,
    this.idMusim,
    required this.mulai,
    this.selesai,
    this.targetDaun = 5,
    this.catatan = '',
  });

  bool get selesaiDilakukan => selesai != null;

  factory SesiSurvei.fromDb(Map<String, dynamic> row) => SesiSurvei(
    idSesi: row['id_sesi'] as int?,
    idPetak: row['id_petak'] as int,
    idMusim: row['id_musim'] as int?,
    mulai: DateTime.parse(row['mulai'] as String),
    selesai: DateTime.tryParse(row['selesai'] as String? ?? ''),
    targetDaun: row['target_daun'] as int? ?? 5,
    catatan: row['catatan'] as String? ?? '',
  );

  Map<String, dynamic> toDb() => {
    if (idSesi != null) 'id_sesi': idSesi,
    'id_petak': idPetak,
    'id_musim': idMusim,
    'mulai': mulai.toIso8601String(),
    'selesai': selesai?.toIso8601String(),
    'target_daun': targetDaun,
    'catatan': catatan.trim(),
  };
}

class PengamatanSurvei {
  final String idPenyakit;
  final bool tidakPasti;

  const PengamatanSurvei({required this.idPenyakit, required this.tidakPasti});
}

class RingkasanSesi {
  final int totalDaun;
  final int jumlahTidakPasti;
  final Map<String, int> jumlahPerKelas;

  const RingkasanSesi({
    required this.totalDaun,
    required this.jumlahTidakPasti,
    required this.jumlahPerKelas,
  });

  factory RingkasanSesi.dariPengamatan(List<PengamatanSurvei> daftar) {
    final jumlah = <String, int>{};
    var tidakPasti = 0;
    for (final item in daftar) {
      if (item.tidakPasti) {
        tidakPasti++;
      } else {
        jumlah.update(item.idPenyakit, (nilai) => nilai + 1, ifAbsent: () => 1);
      }
    }
    return RingkasanSesi(
      totalDaun: daftar.length,
      jumlahTidakPasti: tidakPasti,
      jumlahPerKelas: Map.unmodifiable(jumlah),
    );
  }

  String? get kelasDominan {
    if (jumlahPerKelas.isEmpty) return null;
    return jumlahPerKelas.entries.reduce((a, b) {
      if (a.value != b.value) return a.value > b.value ? a : b;
      return a.key.compareTo(b.key) <= 0 ? a : b;
    }).key;
  }
}

/// Catatan pengamatan kondisi tanaman manual (PRD F-13, S-13, Tabel 13.5 `observations`).
class CatatanPengamatan {
  final int? idPengamatan;
  final int idPetak;
  final int? idRiwayat;
  final DateTime tanggal;
  final String kondisiTanaman;
  final String gejalaDiamati;
  final String tindakanDilakukan;
  final String catatanTambahan;
  final String? pathFoto;
  final DateTime dibuatPada;

  const CatatanPengamatan({
    this.idPengamatan,
    required this.idPetak,
    this.idRiwayat,
    required this.tanggal,
    required this.kondisiTanaman,
    this.gejalaDiamati = '',
    this.tindakanDilakukan = '',
    this.catatanTambahan = '',
    this.pathFoto,
    required this.dibuatPada,
  });

  factory CatatanPengamatan.fromDb(Map<String, dynamic> row) =>
      CatatanPengamatan(
        idPengamatan: row['id_pengamatan'] as int?,
        idPetak: row['id_petak'] as int,
        idRiwayat: row['id_riwayat'] as int?,
        tanggal:
            DateTime.tryParse(row['tanggal'] as String? ?? '') ??
            DateTime.now(),
        kondisiTanaman: (row['kondisi_tanaman'] as String?) ?? '',
        gejalaDiamati: (row['gejala_diamati'] as String?) ?? '',
        tindakanDilakukan: (row['tindakan_dilakukan'] as String?) ?? '',
        catatanTambahan: (row['catatan_tambahan'] as String?) ?? '',
        pathFoto: (row['path_foto'] as String?)?.isNotEmpty == true
            ? row['path_foto'] as String
            : null,
        dibuatPada:
            DateTime.tryParse(row['dibuat_pada'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toDb() => {
    if (idPengamatan != null) 'id_pengamatan': idPengamatan,
    'id_petak': idPetak,
    'id_riwayat': idRiwayat,
    'tanggal': tanggal.toIso8601String(),
    'kondisi_tanaman': kondisiTanaman.trim(),
    'gejala_diamati': gejalaDiamati.trim(),
    'tindakan_dilakukan': tindakanDilakukan.trim(),
    'catatan_tambahan': catatanTambahan.trim(),
    'path_foto': pathFoto ?? '',
    'dibuat_pada': dibuatPada.toIso8601String(),
  };
}

/// Jadwal perawatan tanaman lokal (PRD F-16, S-16, Tabel 13.6 `schedules`).
class JadwalPerawatan {
  final int? idJadwal;
  final int idPetak;
  final String? namaPetak;
  final String judul;
  final String catatan;
  final DateTime tanggalJadwal;
  final bool pengingatAktif;
  final bool selesai;

  const JadwalPerawatan({
    this.idJadwal,
    required this.idPetak,
    this.namaPetak,
    required this.judul,
    this.catatan = '',
    required this.tanggalJadwal,
    this.pengingatAktif = false,
    this.selesai = false,
  });

  static const List<String> jenisKegiatanAwal = [
    'Pemeriksaan kondisi daun',
    'Pemupukan',
    'Pengairan',
    'Pengamatan gejala',
    'Perawatan tanaman',
    'Kegiatan lain',
  ];

  factory JadwalPerawatan.fromDb(
    Map<String, dynamic> row, {
    String? namaPetak,
  }) => JadwalPerawatan(
    idJadwal: row['id_jadwal'] as int?,
    idPetak: row['id_petak'] as int,
    namaPetak: namaPetak ?? (row['nama_petak'] as String?),
    judul: (row['judul'] as String?) ?? 'Pemeriksaan kondisi daun',
    catatan: (row['catatan'] as String?) ?? '',
    tanggalJadwal:
        DateTime.tryParse(row['tanggal_jadwal'] as String? ?? '') ??
        DateTime.now(),
    pengingatAktif: (row['pengingat_aktif'] as int? ?? 0) == 1,
    selesai: (row['status'] as String? ?? 'pending') == 'completed',
  );

  Map<String, dynamic> toDb() => {
    if (idJadwal != null) 'id_jadwal': idJadwal,
    'id_petak': idPetak,
    'judul': judul.trim(),
    'catatan': catatan.trim(),
    'tanggal_jadwal': tanggalJadwal.toIso8601String(),
    'pengingat_aktif': pengingatAktif ? 1 : 0,
    'status': selesai ? 'completed' : 'pending',
  };
}
