import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/catatan_lapangan.dart';
import '../models/hasil_identifikasi.dart';
import '../models/penyakit.dart';

/// Pengelola basis data lokal SQLite (PRD Bagian 6 F-09..F-14 & Bagian 13).
///
/// Mengelola tabel:
/// - `penyakit` (`diseases`) & `rekomendasi` (`recommendations`)
/// - `riwayat` (`diagnoses`)
/// - `petak` (`farms`)
/// - `musim_tanam` & `sesi_survei`
/// - `pengamatan` (`observations`)
/// - `jadwal_perawatan` (`schedules`)
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _dbName = 'padi_scan.db';
  static const int _dbVersion = 5;
  static const String _seedAsset = 'assets/data/penyakit.json';

  Database? _db;
  final ValueNotifier<int> perubahanRiwayat = ValueNotifier<int>(0);

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE penyakit(
            id_penyakit TEXT PRIMARY KEY,
            label_model TEXT NOT NULL,
            nama TEXT NOT NULL,
            nama_latin TEXT,
            penyebab TEXT,
            gejala TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE rekomendasi(
            id_rekomendasi INTEGER PRIMARY KEY AUTOINCREMENT,
            id_penyakit TEXT NOT NULL,
            kategori TEXT NOT NULL,
            isi TEXT NOT NULL,
            sumber TEXT,
            FOREIGN KEY(id_penyakit) REFERENCES penyakit(id_penyakit)
          )
        ''');
        await db.execute('''
          CREATE TABLE riwayat(
            id_riwayat INTEGER PRIMARY KEY AUTOINCREMENT,
            path_foto TEXT NOT NULL,
            id_penyakit TEXT,
            keyakinan REAL NOT NULL,
            waktu TEXT NOT NULL,
            id_petak INTEGER,
            id_musim INTEGER,
            id_sesi INTEGER,
            status TEXT NOT NULL DEFAULT 'terklasifikasi',
            aturan TEXT NOT NULL DEFAULT '',
            waktu_praproses_ms INTEGER NOT NULL DEFAULT 0,
            waktu_inferensi_ms INTEGER NOT NULL DEFAULT 0,
            waktu_total_ms INTEGER NOT NULL DEFAULT 0,
            foto_gelap INTEGER NOT NULL DEFAULT 0,
            foto_buram INTEGER NOT NULL DEFAULT 0,
            model_version TEXT NOT NULL DEFAULT 'tidak-tercatat',
            probabilitas_json TEXT NOT NULL DEFAULT '{}',
            audit_tersedia INTEGER NOT NULL DEFAULT 1,
            catatan_pengguna TEXT NOT NULL DEFAULT '',
            status_penanganan TEXT NOT NULL DEFAULT 'belum_ditangani'
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_riwayat_waktu ON riwayat(waktu DESC)',
        );
        await _seed(db);
        await _buatTabelLapangan(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _migrasiV1KeV2(db);
        }
        if (oldVersion < 3) {
          await _migrasiV2KeV3(db);
        }
        if (oldVersion < 4) {
          await _migrasiV3KeV4(db);
        }
        if (oldVersion < 5) {
          await _migrasiV4KeV5(db);
        }
      },
    );
  }

  Future<void> _tambahKolomAman(
    Database db,
    String tabel,
    String kolom,
    String definisi,
  ) async {
    try {
      await db.execute('ALTER TABLE $tabel ADD COLUMN $kolom $definisi');
    } on Object catch (e) {
      debugPrint('[DB] kolom $tabel.$kolom dilewati: $e');
    }
  }

  Future<void> _migrasiV1KeV2(Database db) async {
    const kolom = <String, String>{
      'id_petak': 'INTEGER',
      'id_musim': 'INTEGER',
      'id_sesi': 'INTEGER',
      'status': "TEXT NOT NULL DEFAULT 'terklasifikasi'",
      'aturan': "TEXT NOT NULL DEFAULT ''",
      'waktu_praproses_ms': 'INTEGER NOT NULL DEFAULT 0',
      'waktu_inferensi_ms': 'INTEGER NOT NULL DEFAULT 0',
      'waktu_total_ms': 'INTEGER NOT NULL DEFAULT 0',
      'foto_gelap': 'INTEGER NOT NULL DEFAULT 0',
      'foto_buram': 'INTEGER NOT NULL DEFAULT 0',
      'model_version': "TEXT NOT NULL DEFAULT 'tidak-tercatat'",
      'probabilitas_json': "TEXT NOT NULL DEFAULT '{}'",
    };
    for (final item in kolom.entries) {
      await _tambahKolomAman(db, 'riwayat', item.key, item.value);
    }
    await db.execute('''
      UPDATE riwayat
      SET status = CASE
        WHEN id_penyakit IS NULL OR id_penyakit = '' THEN 'tidak_pasti'
        WHEN id_penyakit = 'normal' THEN 'sehat'
        ELSE 'terklasifikasi'
      END
    ''');
    await _buatTabelLapangan(db);
  }

  Future<void> _migrasiV2KeV3(Database db) async {
    await _tambahKolomAman(
      db,
      'riwayat',
      'audit_tersedia',
      'INTEGER NOT NULL DEFAULT 0',
    );
    await db.delete('rekomendasi');
    await _seed(db);
  }

  Future<void> _migrasiV3KeV4(Database db) async {
    await _tambahKolomAman(
      db,
      'petak',
      'varietas',
      "TEXT NOT NULL DEFAULT ''",
    );
    await _tambahKolomAman(db, 'petak', 'tanggal_tanam', 'TEXT');
  }

  Future<void> _migrasiV4KeV5(Database db) async {
    await _tambahKolomAman(
      db,
      'petak',
      'satuan_luas',
      "TEXT NOT NULL DEFAULT 'ha'",
    );
    await _tambahKolomAman(
      db,
      'petak',
      'catatan',
      "TEXT NOT NULL DEFAULT ''",
    );
    await _tambahKolomAman(
      db,
      'riwayat',
      'catatan_pengguna',
      "TEXT NOT NULL DEFAULT ''",
    );
    await _tambahKolomAman(
      db,
      'riwayat',
      'status_penanganan',
      "TEXT NOT NULL DEFAULT 'belum_ditangani'",
    );
    await _buatTabelLapangan(db);
  }

  Future<void> _buatTabelLapangan(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS petak(
        id_petak INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        lokasi_catatan TEXT NOT NULL DEFAULT '',
        luas_hektare REAL,
        satuan_luas TEXT NOT NULL DEFAULT 'ha',
        varietas TEXT NOT NULL DEFAULT '',
        tanggal_tanam TEXT,
        catatan TEXT NOT NULL DEFAULT '',
        dibuat_pada TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS musim_tanam(
        id_musim INTEGER PRIMARY KEY AUTOINCREMENT,
        id_petak INTEGER NOT NULL,
        nama TEXT NOT NULL,
        mulai TEXT NOT NULL,
        selesai TEXT,
        aktif INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY(id_petak) REFERENCES petak(id_petak) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sesi_survei(
        id_sesi INTEGER PRIMARY KEY AUTOINCREMENT,
        id_petak INTEGER NOT NULL,
        id_musim INTEGER,
        mulai TEXT NOT NULL,
        selesai TEXT,
        target_daun INTEGER NOT NULL DEFAULT 5,
        catatan TEXT NOT NULL DEFAULT '',
        FOREIGN KEY(id_petak) REFERENCES petak(id_petak) ON DELETE CASCADE,
        FOREIGN KEY(id_musim) REFERENCES musim_tanam(id_musim) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pengamatan(
        id_pengamatan INTEGER PRIMARY KEY AUTOINCREMENT,
        id_petak INTEGER NOT NULL,
        id_riwayat INTEGER,
        tanggal TEXT NOT NULL,
        kondisi_tanaman TEXT NOT NULL DEFAULT '',
        gejala_diamati TEXT NOT NULL DEFAULT '',
        tindakan_dilakukan TEXT NOT NULL DEFAULT '',
        catatan_tambahan TEXT NOT NULL DEFAULT '',
        path_foto TEXT NOT NULL DEFAULT '',
        dibuat_pada TEXT NOT NULL,
        FOREIGN KEY(id_petak) REFERENCES petak(id_petak) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS jadwal_perawatan(
        id_jadwal INTEGER PRIMARY KEY AUTOINCREMENT,
        id_petak INTEGER NOT NULL,
        judul TEXT NOT NULL,
        catatan TEXT NOT NULL DEFAULT '',
        tanggal_jadwal TEXT NOT NULL,
        pengingat_aktif INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'pending',
        FOREIGN KEY(id_petak) REFERENCES petak(id_petak) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_riwayat_petak_waktu '
      'ON riwayat(id_petak, waktu DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sesi_petak_mulai '
      'ON sesi_survei(id_petak, mulai DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pengamatan_petak_tanggal '
      'ON pengamatan(id_petak, tanggal DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_jadwal_petak_tanggal '
      'ON jadwal_perawatan(id_petak, tanggal_jadwal ASC)',
    );
  }

  /// Mengisi tabel `penyakit` dan `rekomendasi` dari aset JSON.
  Future<void> _seed(Database db) async {
    final raw = await rootBundle.loadString(_seedAsset);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final kelas = (data['kelas'] as List<dynamic>).cast<Map<String, dynamic>>();

    final batch = db.batch();
    for (final item in kelas) {
      final penyakit = Penyakit.fromJson(item);
      batch.insert(
        'penyakit',
        penyakit.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final r in penyakit.rekomendasi) {
        batch.insert('rekomendasi', {
          'id_penyakit': penyakit.idPenyakit,
          'kategori': r.kategori.kode,
          'isi': r.isi,
          'sumber': r.sumber,
        });
      }
    }
    await batch.commit(noResult: true);
  }

  // ---------------------------------------------------------------- penyakit

  Future<List<Penyakit>> semuaPenyakit() async {
    final db = await database;
    final rows = await db.query('penyakit');
    final list = rows.map(Penyakit.fromDb).toList();
    const urutanKode = {
      'blas': 0,
      'hawar_daun_bakteri': 1,
      'bercak_cokelat': 2,
      'normal': 3,
    };
    list.sort(
      (a, b) => (urutanKode[a.idPenyakit] ?? 9).compareTo(
        urutanKode[b.idPenyakit] ?? 9,
      ),
    );
    return list;
  }

  /// Mengambil satu penyakit beserta seluruh rekomendasinya.
  Future<Penyakit?> penyakitById(String idPenyakit) async {
    final db = await database;
    final rows = await db.query(
      'penyakit',
      where: 'id_penyakit = ?',
      whereArgs: [idPenyakit],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final rekRows = await db.query(
      'rekomendasi',
      where: 'id_penyakit = ?',
      whereArgs: [idPenyakit],
      orderBy:
          "CASE kategori WHEN 'kultur_teknis' THEN 0 "
          "WHEN 'hayati' THEN 1 ELSE 2 END, id_rekomendasi",
    );

    final base = Penyakit.fromDb(rows.first);
    return Penyakit(
      idPenyakit: base.idPenyakit,
      labelModel: base.labelModel,
      nama: base.nama,
      namaLatin: base.namaLatin,
      penyebab: base.penyebab,
      gejala: base.gejala,
      rekomendasi: rekRows.map(Rekomendasi.fromDb).toList(),
    );
  }

  // ----------------------------------------------------------------- riwayat

  Future<int> simpanRiwayat(Riwayat riwayat) async {
    final db = await database;
    final id = await db.insert('riwayat', riwayat.toDb());
    perubahanRiwayat.value++;
    return id;
  }

  Future<List<Riwayat>> semuaRiwayat({int? batas}) async {
    final db = await database;
    final petakRows = await db.query('petak');
    final petaPetak = <int, String>{
      for (final r in petakRows)
        if (r['id_petak'] is int) r['id_petak'] as int: r['nama'] as String,
    };
    final rows = await db.query('riwayat', orderBy: 'waktu DESC', limit: batas);

    final hasil = <Riwayat>[];
    for (final row in rows) {
      final id = (row['id_penyakit'] as String?) ?? '';
      final penyakit = await penyakitById(id);
      final idPetak = row['id_petak'] as int?;
      hasil.add(
        Riwayat.fromDb(
          row,
          penyakit: penyakit,
          namaPetak: idPetak != null ? petaPetak[idPetak] : null,
        ),
      );
    }
    return hasil;
  }

  Future<List<Riwayat>> timelinePetak(int idPetak, {int? batas}) async {
    final db = await database;
    final petakRows = await db.query(
      'petak',
      where: 'id_petak = ?',
      whereArgs: [idPetak],
      limit: 1,
    );
    final namaPetak = petakRows.isNotEmpty
        ? petakRows.first['nama'] as String?
        : null;
    final rows = await db.query(
      'riwayat',
      where: 'id_petak = ?',
      whereArgs: [idPetak],
      orderBy: 'waktu DESC',
      limit: batas,
    );
    final hasil = <Riwayat>[];
    for (final row in rows) {
      final id = row['id_penyakit'] as String? ?? '';
      hasil.add(
        Riwayat.fromDb(
          row,
          penyakit: await penyakitById(id),
          namaPetak: namaPetak,
        ),
      );
    }
    return hasil;
  }

  Future<List<Riwayat>> riwayatSesi(int idSesi) async {
    final db = await database;
    final rows = await db.query(
      'riwayat',
      where: 'id_sesi = ?',
      whereArgs: [idSesi],
      orderBy: 'waktu ASC',
    );
    return rows.map(Riwayat.fromDb).toList();
  }

  Future<void> kelompokkanRiwayat({
    required int idRiwayat,
    required int? idPetak,
    int? idMusim,
  }) async {
    final db = await database;
    await db.update(
      'riwayat',
      {'id_petak': idPetak, 'id_musim': idMusim},
      where: 'id_riwayat = ?',
      whereArgs: [idRiwayat],
    );
    perubahanRiwayat.value++;
  }

  Future<void> perbaruiDetailRiwayat({
    required int idRiwayat,
    int? idPetak,
    bool ubahPetak = false,
    String? catatanPengguna,
    String? statusPenanganan,
  }) async {
    final db = await database;
    final nilai = <String, Object?>{};
    if (ubahPetak) nilai['id_petak'] = idPetak;
    if (catatanPengguna != null) {
      nilai['catatan_pengguna'] = catatanPengguna.trim();
    }
    if (statusPenanganan != null) {
      nilai['status_penanganan'] = statusPenanganan.trim();
    }
    if (nilai.isEmpty) return;
    await db.update(
      'riwayat',
      nilai,
      where: 'id_riwayat = ?',
      whereArgs: [idRiwayat],
    );
    perubahanRiwayat.value++;
  }

  // ---------------------------------------------------------- lahan (`petak`)

  Future<int> simpanPetak(Petak petak) async {
    final db = await database;
    if (petak.idPetak == null) {
      final id = await db.insert('petak', petak.toDb());
      perubahanRiwayat.value++;
      return id;
    }
    await db.update(
      'petak',
      petak.toDb(),
      where: 'id_petak = ?',
      whereArgs: [petak.idPetak],
    );
    perubahanRiwayat.value++;
    return petak.idPetak!;
  }

  Future<List<Petak>> semuaPetak() async {
    final db = await database;
    final rows = await db.query('petak', orderBy: 'nama COLLATE NOCASE');
    return rows.map(Petak.fromDb).toList();
  }

  /// Menghapus lahan tanpa menghapus riwayat identifikasi petani (PRD F-11).
  Future<void> hapusPetak(int idPetak) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'riwayat',
        {'id_petak': null, 'id_musim': null, 'id_sesi': null},
        where: 'id_petak = ?',
        whereArgs: [idPetak],
      );
      await txn.delete(
        'jadwal_perawatan',
        where: 'id_petak = ?',
        whereArgs: [idPetak],
      );
      await txn.delete(
        'pengamatan',
        where: 'id_petak = ?',
        whereArgs: [idPetak],
      );
      await txn.delete(
        'sesi_survei',
        where: 'id_petak = ?',
        whereArgs: [idPetak],
      );
      await txn.delete(
        'musim_tanam',
        where: 'id_petak = ?',
        whereArgs: [idPetak],
      );
      await txn.delete('petak', where: 'id_petak = ?', whereArgs: [idPetak]);
    });
    perubahanRiwayat.value++;
  }

  Future<int> simpanMusim(MusimTanam musim) async {
    final db = await database;
    if (musim.idMusim == null) return db.insert('musim_tanam', musim.toDb());
    await db.update(
      'musim_tanam',
      musim.toDb(),
      where: 'id_musim = ?',
      whereArgs: [musim.idMusim],
    );
    return musim.idMusim!;
  }

  Future<List<MusimTanam>> musimUntukPetak(int idPetak) async {
    final db = await database;
    final rows = await db.query(
      'musim_tanam',
      where: 'id_petak = ?',
      whereArgs: [idPetak],
      orderBy: 'mulai DESC',
    );
    return rows.map(MusimTanam.fromDb).toList();
  }

  Future<void> akhiriMusimPetak(int idPetak, DateTime selesai) async {
    final db = await database;
    await db.update(
      'musim_tanam',
      {'aktif': 0, 'selesai': selesai.toIso8601String()},
      where: 'id_petak = ? AND aktif = 1',
      whereArgs: [idPetak],
    );
  }

  Future<int> mulaiSesi(SesiSurvei sesi) async {
    final db = await database;
    return db.insert('sesi_survei', sesi.toDb());
  }

  Future<void> selesaikanSesi(int idSesi, DateTime selesai) async {
    final db = await database;
    await db.update(
      'sesi_survei',
      {'selesai': selesai.toIso8601String()},
      where: 'id_sesi = ?',
      whereArgs: [idSesi],
    );
  }

  Future<List<SesiSurvei>> sesiUntukPetak(int idPetak) async {
    final db = await database;
    final rows = await db.query(
      'sesi_survei',
      where: 'id_petak = ?',
      whereArgs: [idPetak],
      orderBy: 'mulai DESC',
    );
    return rows.map(SesiSurvei.fromDb).toList();
  }

  // ------------------------------------------------ catatan pengamatan manual

  Future<int> simpanPengamatan(CatatanPengamatan pengamatan) async {
    final db = await database;
    if (pengamatan.idPengamatan == null) {
      final id = await db.insert('pengamatan', pengamatan.toDb());
      perubahanRiwayat.value++;
      return id;
    }
    await db.update(
      'pengamatan',
      pengamatan.toDb(),
      where: 'id_pengamatan = ?',
      whereArgs: [pengamatan.idPengamatan],
    );
    perubahanRiwayat.value++;
    return pengamatan.idPengamatan!;
  }

  Future<List<CatatanPengamatan>> pengamatanUntukPetak(int idPetak) async {
    final db = await database;
    final rows = await db.query(
      'pengamatan',
      where: 'id_petak = ?',
      whereArgs: [idPetak],
      orderBy: 'tanggal DESC, id_pengamatan DESC',
    );
    return rows.map(CatatanPengamatan.fromDb).toList();
  }

  Future<List<CatatanPengamatan>> semuaPengamatan({int? batas}) async {
    final db = await database;
    final rows = await db.query(
      'pengamatan',
      orderBy: 'tanggal DESC, id_pengamatan DESC',
      limit: batas,
    );
    return rows.map(CatatanPengamatan.fromDb).toList();
  }

  Future<void> hapusPengamatan(int idPengamatan) async {
    final db = await database;
    await db.delete(
      'pengamatan',
      where: 'id_pengamatan = ?',
      whereArgs: [idPengamatan],
    );
    perubahanRiwayat.value++;
  }

  // -------------------------------------------------------- jadwal perawatan

  Future<int> simpanJadwal(JadwalPerawatan jadwal) async {
    final db = await database;
    if (jadwal.idJadwal == null) {
      final id = await db.insert('jadwal_perawatan', jadwal.toDb());
      perubahanRiwayat.value++;
      return id;
    }
    await db.update(
      'jadwal_perawatan',
      jadwal.toDb(),
      where: 'id_jadwal = ?',
      whereArgs: [jadwal.idJadwal],
    );
    perubahanRiwayat.value++;
    return jadwal.idJadwal!;
  }

  Future<List<JadwalPerawatan>> jadwalUntukPetak(int idPetak) async {
    final db = await database;
    final rows = await db.query(
      'jadwal_perawatan',
      where: 'id_petak = ?',
      whereArgs: [idPetak],
      orderBy: "CASE status WHEN 'pending' THEN 0 ELSE 1 END, tanggal_jadwal ASC",
    );
    return rows.map(JadwalPerawatan.fromDb).toList();
  }

  Future<List<JadwalPerawatan>> semuaJadwalMendatang({int? batas}) async {
    final db = await database;
    final petakRows = await db.query('petak');
    final petaPetak = <int, String>{
      for (final r in petakRows)
        if (r['id_petak'] is int) r['id_petak'] as int: r['nama'] as String,
    };
    final rows = await db.query(
      'jadwal_perawatan',
      where: "status = 'pending'",
      orderBy: 'tanggal_jadwal ASC',
      limit: batas,
    );
    return [
      for (final r in rows)
        JadwalPerawatan.fromDb(
          r,
          namaPetak: petaPetak[r['id_petak'] as int? ?? -1],
        ),
    ];
  }

  Future<void> ubahStatusJadwal(int idJadwal, bool selesai) async {
    final db = await database;
    await db.update(
      'jadwal_perawatan',
      {'status': selesai ? 'completed' : 'pending'},
      where: 'id_jadwal = ?',
      whereArgs: [idJadwal],
    );
    perubahanRiwayat.value++;
  }

  Future<void> hapusJadwal(int idJadwal) async {
    final db = await database;
    await db.delete(
      'jadwal_perawatan',
      where: 'id_jadwal = ?',
      whereArgs: [idJadwal],
    );
    perubahanRiwayat.value++;
  }

  // ----------------------------------------------------------- penghapusan

  Future<void> hapusRiwayat(int idRiwayat) async {
    final db = await database;
    await db.delete('riwayat', where: 'id_riwayat = ?', whereArgs: [idRiwayat]);
    perubahanRiwayat.value++;
  }

  Future<void> hapusSemuaRiwayat() async {
    final db = await database;
    await db.delete('riwayat');
    perubahanRiwayat.value++;
  }

  Future<int> hapusSemuaRiwayatDanFoto() async {
    final data = await semuaRiwayat();
    for (final item in data) {
      await hapusFoto(item.pathFoto);
    }
    final db = await database;
    final jumlah = await db.delete('riwayat');
    perubahanRiwayat.value++;
    return jumlah;
  }

  Future<void> hapusSeluruhDataLokal() async {
    final data = await semuaRiwayat();
    for (final item in data) {
      await hapusFoto(item.pathFoto);
    }
    final pengamatan = await semuaPengamatan();
    for (final item in pengamatan) {
      if (item.pathFoto != null) {
        await hapusFoto(item.pathFoto!);
      }
    }
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('jadwal_perawatan');
      await txn.delete('pengamatan');
      await txn.delete('sesi_survei');
      await txn.delete('musim_tanam');
      await txn.delete('riwayat');
      await txn.delete('petak');
    });
    perubahanRiwayat.value++;
  }

  // ------------------------------------------------------------------ berkas

  Future<String> salinFotoKeAplikasi(String pathAsal) async {
    final dir = await getApplicationDocumentsDirectory();
    final fotoDir = Directory(p.join(dir.path, 'foto'));
    if (!await fotoDir.exists()) {
      await fotoDir.create(recursive: true);
    }

    final nama =
        'daun_${DateTime.now().millisecondsSinceEpoch}'
        '${p.extension(pathAsal).isEmpty ? '.jpg' : p.extension(pathAsal)}';
    final tujuan = p.join(fotoDir.path, nama);
    await File(pathAsal).copy(tujuan);
    return tujuan;
  }

  Future<void> hapusFoto(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
