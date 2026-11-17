/// Model data untuk satu kelas penyakit daun padi (PRD Bagian 1.4, F-08, F-10).
///
/// Mengikuti rancangan tabel `penyakit` / `diseases` dan `rekomendasi` /
/// `recommendations`.
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

  /// Kelompok rekomendasi sesuai PHT (kultur teknis didahulukan).
  List<Rekomendasi> get rekomendasiKulturTeknis => rekomendasi
      .where((r) => r.kategori == KategoriRekomendasi.kulturTeknis)
      .toList();

  List<Rekomendasi> get rekomendasiHayati => rekomendasi
      .where((r) => r.kategori == KategoriRekomendasi.hayati)
      .toList();

  List<Rekomendasi> get rekomendasiKimia => rekomendasi
      .where((r) => r.kategori == KategoriRekomendasi.kimia)
      .toList();

  /// Daun sehat tidak perlu menampilkan rekomendasi pengendalian penyakit.
  bool get isSehat => idPenyakit == 'normal';

  /// Kode kelas PRD Bagian 1.4 (C01..C04).
  String get kodeKelas => kodeDariId(idPenyakit);

  /// Path aset foto tanaman padi asli (PRD Bagian 4.2 & F-10).
  String get pathGambar => gambarDariId(idPenyakit);

  /// Penjelasan singkat untuk halaman hasil dan rekomendasi (PRD F-07 & F-08).
  String get penjelasanSingkat => penjelasanDariId(idPenyakit);

  /// Faktor lingkungan pendukung perkembangan penyakit (PRD F-10 & S-15).
  String get faktorPendukung => faktorDariId(idPenyakit);

  /// Langkah pengamatan lanjutan di lahan (PRD F-08).
  String get langkahPengamatan => pengamatanLanjutanDariId(idPenyakit);

  /// Ringkasan pencegahan utama (PRD F-08 & S-15).
  String get pencegahan => pencegahanDariId(idPenyakit);

  /// Daftar butir gejala visual untuk halaman hasil (PRD S-07).
  List<String> get daftarGejala => gejalaDaftarDariId(idPenyakit);

  /// Tanggal peninjauan konten basis pengetahuan lokal (PRD F-08).
  String get tanggalPeninjauan => '16 November 2026';

  /// Nama tampilan Bahasa Indonesia berdasarkan ID kelas model (NF-04).
  static String namaDariId(String id) => switch (id) {
    'bercak_cokelat' => 'Bercak Cokelat',
    'blas' => 'Blas (Blas Daun)',
    'hawar_daun_bakteri' => 'Hawar Daun Bakteri (HDB)',
    'normal' => 'Daun Sehat',
    '' => 'Belum Meyakinkan',
    _ => id,
  };

  static String kodeDariId(String id) => switch (id) {
    'blas' => 'C01',
    'hawar_daun_bakteri' => 'C02',
    'bercak_cokelat' => 'C03',
    'normal' => 'C04',
    _ => '-',
  };

  static String gambarDariId(String id) => switch (id) {
    'blas' => 'assets/images/blas.jpg',
    'hawar_daun_bakteri' => 'assets/images/hawar_daun_bakteri.jpg',
    'bercak_cokelat' => 'assets/images/bercak_cokelat.jpg',
    'normal' => 'assets/images/normal.jpg',
    _ => 'assets/images/normal.jpg',
  };

  static String penjelasanDariId(String id) => switch (id) {
    'blas' =>
      'Model menemukan pola yang sesuai dengan blas daun. Cocokkan hasil '
          'dengan bercak belah ketupat yang terlihat pada tanaman sebelum '
          'melakukan penanganan.',
    'hawar_daun_bakteri' =>
      'Model menemukan pola yang sesuai dengan hawar daun bakteri. Cocokkan '
          'hasil dengan gejala garis menguning dan mengering dari ujung '
          'atau tepi daun.',
    'bercak_cokelat' =>
      'Model menemukan pola yang sesuai dengan bercak cokelat. Cocokkan '
          'hasil dengan bercak lonjong kecokelatan berpusat keabu-abuan '
          'pada daun dewasa.',
    'normal' =>
      'Permukaan daun tampak hijau merata tanpa ciri bercak atau hawar. '
          'Tetap lakukan pemantauan rutin pada petak lahan.',
    _ =>
      'Hasil belum cukup meyakinkan. Coba ambil foto daun yang lebih jelas.',
  };

  static String faktorDariId(String id) => switch (id) {
    'blas' =>
      'Kelembapan udara tinggi (>90%), embun pagi tebal, pemupukan nitrogen '
          '(urea) berlebihan, serta jarak tanam terlalu rapat.',
    'hawar_daun_bakteri' =>
      'Curah hujan tinggi disertai angin kencang, genangan air terus-menerus, '
          'luka gesekan antar daun, dan dosis pupuk nitrogen tinggi.',
    'bercak_cokelat' =>
      'Tanah kahat unsur kalium/silika, drainase kurang baik, kekeringan '
          'berselang, atau penggunaan benih yang sudah terinfeksi.',
    'normal' =>
      'Pemupukan berimbang, jarak tanam teratur (seperti jajar legowo), '
          'pengairan berselang, dan sanitasi gulma yang terjaga.',
    _ => '-',
  };

  static String pengamatanLanjutanDariId(String id) => switch (id) {
    'blas' =>
      'Periksa 10–20 rumpun secara diagonal di petak lahan. Amati apakah '
          'bercak belah ketupat meluas ke buku batang atau leher malai '
          '(blas leher) terutama saat menjelang keluar malai.',
    'hawar_daun_bakteri' =>
      'Amati tepi daun dari ujung ke pangkal pada pagi hari untuk melihat '
          'eksudat bakteri (butiran kuning keruh), dan periksa apakah '
          'anakan muda mengalami layu kresek.',
    'bercak_cokelat' =>
      'Periksa daun bagian bawah hingga tengah serta kondisi perakaran dan '
          'kecukupan pupuk kalium pada petak yang terdampak.',
    'normal' =>
      'Lanjutkan pengamatan berkala setiap 7 hari sekali pada daun bendera, '
          'pelepah, dan malai.',
    _ =>
      'Ambil ulang foto satu helai daun secara fokus dengan pencahayaan '
          'cukup dan tanpa bayangan.',
  };

  static String pencegahanDariId(String id) => switch (id) {
    'blas' =>
      'Gunakan varietas tahan sesuai sebaran ras setempat, atur jarak tanam '
          'jajar legowo, berikan nitrogen secara bertahap dan berimbang '
          'dengan kalium, serta benamkan sisa jerami terinfeksi.',
    'hawar_daun_bakteri' =>
      'Gunakan benih sehat/varietas tahan, hindari pemotongan ujung bibit '
          'saat pindah tanam, terapkan pengairan berselang (intermittent), '
          'dan bersihkan gulma inang di pematang.',
    'bercak_cokelat' =>
      'Seleksi dan perlakukan benih sebelum semai, perbaiki kesuburan tanah '
          'dengan pupuk berimbang (terutama unsur K), dan musnahkan sisa '
          'singgang setelah panen.',
    'normal' =>
      'Pertahankan sanitasi lahan, pengairan berselang, dan pemantauan '
          'rutin agar tanaman tetap sehat hingga fase panen.',
    _ => '-',
  };

  static List<String> gejalaDaftarDariId(String id) => switch (id) {
    'blas' => const [
      'Bercak berbentuk belah ketupat (ujung meruncing)',
      'Bagian tengah bercak berwarna abu-abu/putih dengan tepi cokelat tua',
      'Dapat menyerang leher malai (blas leher) dan menyebabkan gabah hampa',
    ],
    'hawar_daun_bakteri' => const [
      'Garis kebasahan kekuningan dimulai dari ujung atau tepi daun',
      'Lesi memanjang dengan tepi bergelombang hingga mengering keabu-abuan',
      'Pada fase muda dapat memicu gejala kresek (daun menggulung dan layu)',
    ],
    'bercak_cokelat' => const [
      'Bercak oval atau bulat kecil berwarna cokelat gelap',
      'Pusat bercak dewasa berwarna abu-abu dengan lingkaran kuning tipis',
      'Umumnya muncul merata pada daun tua atau tanaman yang kekurangan hara',
    ],
    'normal' => const [
      'Helai daun hijau segar dan merata',
      'Tidak ditemukan bercak belah ketupat maupun tepi daun mengering',
      'Pertumbuhan daun normal tanpa perubahan warna patologis',
    ],
    _ => const [],
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

/// Satu butir rekomendasi penanganan.
class Rekomendasi {
  final int? idRekomendasi;
  final String idPenyakit;
  final KategoriRekomendasi kategori;
  final String isi;
  final String sumber;
  final String ditinjauPada;

  const Rekomendasi({
    this.idRekomendasi,
    required this.idPenyakit,
    required this.kategori,
    required this.isi,
    required this.sumber,
    this.ditinjauPada = '16 November 2026',
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
      ditinjauPada: (json['ditinjau_pada'] as String?) ?? '16 November 2026',
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
