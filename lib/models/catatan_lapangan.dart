/// Data petak sawah yang disimpan sepenuhnya di perangkat.
class Petak {
  final int? idPetak;
  final String nama;
  final String lokasiCatatan;
  final double? luasHektare;
  final String varietas;
  final DateTime? tanggalTanam;
  final DateTime dibuatPada;

  const Petak({
    this.idPetak,
    required this.nama,
    this.lokasiCatatan = '',
    this.luasHektare,
    this.varietas = '',
    this.tanggalTanam,
    required this.dibuatPada,
  });

  factory Petak.fromDb(Map<String, dynamic> row) => Petak(
    idPetak: row['id_petak'] as int?,
    nama: row['nama'] as String,
    lokasiCatatan: (row['lokasi_catatan'] as String?) ?? '',
    luasHektare: (row['luas_hektare'] as num?)?.toDouble(),
    varietas: row['varietas'] as String? ?? '',
    tanggalTanam: DateTime.tryParse(row['tanggal_tanam'] as String? ?? ''),
    dibuatPada:
        DateTime.tryParse(row['dibuat_pada'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  Map<String, dynamic> toDb() => {
    if (idPetak != null) 'id_petak': idPetak,
    'nama': nama.trim(),
    'lokasi_catatan': lokasiCatatan.trim(),
    'luas_hektare': luasHektare,
    'varietas': varietas.trim(),
    'tanggal_tanam': tanggalTanam?.toIso8601String(),
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
