import 'penyakit.dart';

enum StatusIdentifikasi {
  terklasifikasi('terklasifikasi'),
  sehat('sehat'),
  tidakPasti('tidak_pasti'),
  gagalTeknis('gagal_teknis');

  final String kode;
  const StatusIdentifikasi(this.kode);

  static StatusIdentifikasi dariKode(String? kode, String idPenyakit) {
    if (kode == null || kode.isEmpty) {
      return idPenyakit == 'normal' ? sehat : terklasifikasi;
    }
    return values.firstWhere(
      (nilai) => nilai.kode == kode,
      orElse: () => gagalTeknis,
    );
  }
}

/// Hasil identifikasi satu citra (keluaran model + keputusan aturan).
class HasilIdentifikasi {
  /// Kelas dengan probabilitas tertinggi.
  final String idPenyakit;

  /// Nilai probabilitas softmax kelas terpilih (0..1).
  final double keyakinan;

  /// Seluruh probabilitas per kelas, terurut menurun.
  final List<ProbabilitasKelas> semuaProbabilitas;

  /// True bila keyakinan di bawah ambang batas (aturan R5).
  final bool tidakDikenali;

  /// Waktu inferensi model dalam milidetik (NF-02).
  final int waktuInferensiMs;

  /// Waktu prapemrosesan citra; tidak dicampur dengan waktu model.
  final int waktuPraprosesMs;

  /// Waktu keseluruhan dari pembacaan bytes sampai keputusan aturan.
  final int waktuTotalMs;

  /// Kode aturan R1–R5 yang menghasilkan keputusan.
  final String aturan;

  /// Peringatan kualitas yang ikut disimpan untuk audit.
  final List<String> peringatanKualitas;

  final String pathFoto;
  final DateTime waktu;
  final int? idRiwayat;
  final int? idPetak;

  const HasilIdentifikasi({
    required this.idPenyakit,
    required this.keyakinan,
    required this.semuaProbabilitas,
    required this.tidakDikenali,
    required this.waktuInferensiMs,
    this.waktuPraprosesMs = 0,
    int? waktuTotalMs,
    this.aturan = '',
    this.peringatanKualitas = const [],
    required this.pathFoto,
    required this.waktu,
    this.idRiwayat,
    this.idPetak,
  }) : waktuTotalMs = waktuTotalMs ?? waktuInferensiMs;

  /// Keyakinan dalam persen untuk ditampilkan (F-04).
  double get keyakinanPersen => keyakinan * 100;
}

class ProbabilitasKelas {
  final String idPenyakit;
  final double nilai;

  const ProbabilitasKelas({required this.idPenyakit, required this.nilai});

  double get persen => nilai * 100;
}

/// Satu baris tabel `riwayat` / `diagnoses` (PRD F-09 & Tabel 13.3).
class Riwayat {
  final int? idRiwayat;
  final String pathFoto;
  final String idPenyakit;
  final double keyakinan;
  final DateTime waktu;
  final Penyakit? penyakit;
  final int? idPetak;
  final String? namaPetak;
  final int? idMusim;
  final int? idSesi;
  final StatusIdentifikasi status;
  final String aturan;
  final int waktuPraprosesMs;
  final int waktuInferensiMs;
  final int waktuTotalMs;
  final bool fotoGelap;
  final bool fotoBuram;
  final String modelVersion;
  final String probabilitasJson;
  final bool auditTersedia;
  final String catatanPengguna;
  final String statusPenanganan;

  const Riwayat({
    this.idRiwayat,
    required this.pathFoto,
    required this.idPenyakit,
    required this.keyakinan,
    required this.waktu,
    this.penyakit,
    this.idPetak,
    this.namaPetak,
    this.idMusim,
    this.idSesi,
    this.status = StatusIdentifikasi.terklasifikasi,
    this.aturan = '',
    this.waktuPraprosesMs = 0,
    this.waktuInferensiMs = 0,
    this.waktuTotalMs = 0,
    this.fotoGelap = false,
    this.fotoBuram = false,
    this.modelVersion = 'tidak-tercatat',
    this.probabilitasJson = '{}',
    this.auditTersedia = true,
    this.catatanPengguna = '',
    this.statusPenanganan = 'belum_ditangani',
  });

  static String labelStatusPenanganan(String kode) => switch (kode) {
    'dipantau' => 'Sedang dipantau',
    'sudah_ditangani' => 'Sudah ditangani',
    _ => 'Belum ditangani',
  };

  factory Riwayat.fromDb(
    Map<String, dynamic> row, {
    Penyakit? penyakit,
    String? namaPetak,
  }) {
    final idPenyakit = (row['id_penyakit'] as String?) ?? '';
    return Riwayat(
      idRiwayat: row['id_riwayat'] as int?,
      pathFoto: row['path_foto'] as String,
      idPenyakit: idPenyakit,
      keyakinan: (row['keyakinan'] as num).toDouble(),
      waktu: DateTime.tryParse(row['waktu'] as String) ?? DateTime.now(),
      penyakit: penyakit,
      idPetak: row['id_petak'] as int?,
      namaPetak: namaPetak ?? (row['nama_petak'] as String?),
      idMusim: row['id_musim'] as int?,
      idSesi: row['id_sesi'] as int?,
      status: StatusIdentifikasi.dariKode(row['status'] as String?, idPenyakit),
      aturan: row['aturan'] as String? ?? '',
      waktuPraprosesMs: row['waktu_praproses_ms'] as int? ?? 0,
      waktuInferensiMs: row['waktu_inferensi_ms'] as int? ?? 0,
      waktuTotalMs: row['waktu_total_ms'] as int? ?? 0,
      fotoGelap: (row['foto_gelap'] as int? ?? 0) == 1,
      fotoBuram: (row['foto_buram'] as int? ?? 0) == 1,
      modelVersion: row['model_version'] as String? ?? 'tidak-tercatat',
      probabilitasJson: row['probabilitas_json'] as String? ?? '{}',
      auditTersedia: (row['audit_tersedia'] as int? ?? 0) == 1,
      catatanPengguna: (row['catatan_pengguna'] as String?) ?? '',
      statusPenanganan:
          (row['status_penanganan'] as String?)?.isNotEmpty == true
          ? row['status_penanganan'] as String
          : 'belum_ditangani',
    );
  }

  Map<String, dynamic> toDb() => {
    if (idRiwayat != null) 'id_riwayat': idRiwayat,
    'path_foto': pathFoto,
    'id_penyakit': idPenyakit,
    'keyakinan': keyakinan,
    'waktu': waktu.toIso8601String(),
    'id_petak': idPetak,
    'id_musim': idMusim,
    'id_sesi': idSesi,
    'status': status.kode,
    'aturan': aturan,
    'waktu_praproses_ms': waktuPraprosesMs,
    'waktu_inferensi_ms': waktuInferensiMs,
    'waktu_total_ms': waktuTotalMs,
    'foto_gelap': fotoGelap ? 1 : 0,
    'foto_buram': fotoBuram ? 1 : 0,
    'model_version': modelVersion,
    'probabilitas_json': probabilitasJson,
    'audit_tersedia': auditTersedia ? 1 : 0,
    'catatan_pengguna': catatanPengguna.trim(),
    'status_penanganan': statusPenanganan.trim().isEmpty
        ? 'belum_ditangani'
        : statusPenanganan.trim(),
  };
}
