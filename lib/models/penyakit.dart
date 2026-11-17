/// Model data untuk satu kelas penyakit daun padi.
///
/// Mengikuti rancangan tabel `penyakit` pada Tabel 3.6 proposal.
class Penyakit {
  final String idPenyakit;
  final String labelModel;
  final String nama;
  final String namaLatin;
  final String penyebab;
  final String gejala;
  final List<Rekomendasi> rekomendasi;

  const Penyakit({
    required this.idPenyakit,
    required this.labelModel,
    required this.nama,
    required this.namaLatin,
    required this.penyebab,
    required this.gejala,
    this.rekomendasi = const [],
  });

  factory Penyakit.fromJson(Map<String, dynamic> json) {
    return Penyakit(
      idPenyakit: json['id_penyakit'] as String,
      labelModel: json['label_model'] as String,
      nama: json['nama'] as String,
      namaLatin: (json['nama_latin'] as String?) ?? '-',
      penyebab: (json['penyebab'] as String?) ?? '-',
      gejala: (json['gejala'] as String?) ?? '-',
      rekomendasi: ((json['rekomendasi'] as List<dynamic>?) ?? const [])
          .map((e) => Rekomendasi.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory Penyakit.fromDb(Map<String, dynamic> row) {
    return Penyakit(
      idPenyakit: row['id_penyakit'] as String,
      labelModel: (row['label_model'] as String?) ?? '',
      nama: row['nama'] as String,
      namaLatin: (row['nama_latin'] as String?) ?? '-',
      penyebab: (row['penyebab'] as String?) ?? '-',
      gejala: (row['gejala'] as String?) ?? '-',
    );
  }

  Map<String, dynamic> toDb() => {
    'id_penyakit': idPenyakit,
    'label_model': labelModel,
    'nama': nama,
    'nama_latin': namaLatin,
    'penyebab': penyebab,
    'gejala': gejala,
  };

  /// Kelompok rekomendasi sesuai Tabel 2.2 (kultur teknis didahulukan).
  List<Rekomendasi> get rekomendasiKulturTeknis => rekomendasi
      .where((r) => r.kategori == KategoriRekomendasi.kulturTeknis)
      .toList();

  List<Rekomendasi> get rekomendasiHayati => rekomendasi
      .where((r) => r.kategori == KategoriRekomendasi.hayati)
      .toList();

  List<Rekomendasi> get rekomendasiKimia => rekomendasi
      .where((r) => r.kategori == KategoriRekomendasi.kimia)
      .toList();

  /// Daun sehat tidak perlu menampilkan rekomendasi pengendalian.
  bool get isSehat => idPenyakit == 'normal';

  /// Nama tampilan Bahasa Indonesia berdasarkan ID kelas model (NF-04).
  static String namaDariId(String id) => switch (id) {
    'bercak_cokelat' => 'Bercak Cokelat',
    'blas' => 'Blas (Blas Daun)',
    'hawar_daun_bakteri' => 'Hawar Daun Bakteri (HDB)',
    'normal' => 'Daun Sehat',
    '' => 'Tanpa hasil',
    _ => id,
  };
}

enum KategoriRekomendasi {
  kulturTeknis('kultur_teknis', 'Kultur Teknis dan Pencegahan'),
  hayati('hayati', 'Pengendalian Hayati'),
  kimia('kimia', 'Pengendalian Kimia');

  const KategoriRekomendasi(this.kode, this.label);

  final String kode;
  final String label;

  static KategoriRekomendasi fromKode(String kode) {
    return KategoriRekomendasi.values.firstWhere(
      (e) => e.kode == kode,
      orElse: () => KategoriRekomendasi.kulturTeknis,
    );
  }
}

/// Satu butir rekomendasi penanganan. Mengikuti rancangan tabel
/// `rekomendasi` pada Tabel 3.6 proposal.
class Rekomendasi {
  final int? idRekomendasi;
  final String idPenyakit;
  final KategoriRekomendasi kategori;
  final String isi;
  final String sumber;

  const Rekomendasi({
    this.idRekomendasi,
    required this.idPenyakit,
    required this.kategori,
    required this.isi,
    required this.sumber,
  });

  factory Rekomendasi.fromJson(
    Map<String, dynamic> json, {
    String? idPenyakit,
  }) {
    return Rekomendasi(
      idPenyakit: idPenyakit ?? (json['id_penyakit'] as String?) ?? '',
      kategori: KategoriRekomendasi.fromKode(json['kategori'] as String),
      isi: json['isi'] as String,
      sumber: (json['sumber'] as String?) ?? '-',
    );
  }

  factory Rekomendasi.fromDb(Map<String, dynamic> row) {
    return Rekomendasi(
      idRekomendasi: row['id_rekomendasi'] as int?,
      idPenyakit: row['id_penyakit'] as String,
      kategori: KategoriRekomendasi.fromKode(row['kategori'] as String),
      isi: row['isi'] as String,
      sumber: (row['sumber'] as String?) ?? '-',
    );
  }

  Map<String, dynamic> toDb() => {
    if (idRekomendasi != null) 'id_rekomendasi': idRekomendasi,
    'id_penyakit': idPenyakit,
    'kategori': kategori.kode,
    'isi': isi,
    'sumber': sumber,
  };
}
