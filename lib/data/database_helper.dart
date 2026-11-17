import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/hasil_identifikasi.dart';
import '../models/catatan_lapangan.dart';
import '../models/penyakit.dart';

/// Pengelola basis data lokal SQLite (Tabel 3.6).
///
/// Tiga tabel: `penyakit`, `rekomendasi`, dan `riwayat`. Basis data
/// di-seed dari `assets/data/penyakit.json` pada pembukaan pertama.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _dbName = 'padi_scan.db';
  static const int _dbVersion = 4;
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
            probabilitas_json TEXT NOT NULL DEFAULT '{}'
            ,audit_tersedia INTEGER NOT NULL DEFAULT 1
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
      },
    );
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
      await db.execute(
        'ALTER TABLE riwayat ADD COLUMN ${item.key} ${item.value}',
      );
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
    await db.execute(
      'ALTER TABLE riwayat ADD COLUMN audit_tersedia '
      'INTEGER NOT NULL DEFAULT 0',
    );
    await db.delete('rekomendasi');
    await _seed(db);
  }

  Future<void> _migrasiV3KeV4(Database db) async {
    await db.execute(
      "ALTER TABLE petak ADD COLUMN varietas TEXT NOT NULL DEFAULT ''",
    );
    await db.execute('ALTER TABLE petak ADD COLUMN tanggal_tanam TEXT');
  }

  Future<void> _buatTabelLapangan(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS petak(
        id_petak INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        lokasi_catatan TEXT NOT NULL DEFAULT '',
        luas_hektare REAL,
        varietas TEXT NOT NULL DEFAULT '',
        tanggal_tanam TEXT,
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
        FOREIGN KEY(id_petak) REFERENCES petak(id_petak) ON DELETE RESTRICT
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
        FOREIGN KEY(id_petak) REFERENCES petak(id_petak) ON DELETE RESTRICT,
        FOREIGN KEY(id_musim) REFERENCES musim_tanam(id_musim) ON DELETE SET NULL
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
    list.sort((a, b) => a.nama.compareTo(b.nama));
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

  Future<void> simpanRiwayat(Riwayat riwayat) async {
    final db = await database;
    await db.insert('riwayat', riwayat.toDb());
    perubahanRiwayat.value++;
  }

  Future<List<Riwayat>> semuaRiwayat({int? batas}) async {
    final db = await database;
    final rows = await db.query('riwayat', orderBy: 'waktu DESC', limit: batas);

    final hasil = <Riwayat>[];
    for (final row in rows) {
      final id = (row['id_penyakit'] as String?) ?? '';
      final penyakit = await penyakitById(id);
      hasil.add(Riwayat.fromDb(row, penyakit: penyakit));
    }
    return hasil;
  }

  Future<List<Riwayat>> timelinePetak(int idPetak, {int? batas}) async {
    final db = await database;
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
      hasil.add(Riwayat.fromDb(row, penyakit: await penyakitById(id)));
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
    required int idPetak,
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

  // ---------------------------------------------------------- catatan lapangan

  Future<int> simpanPetak(Petak petak) async {
    final db = await database;
    if (petak.idPetak == null) return db.insert('petak', petak.toDb());
    await db.update(
      'petak',
      petak.toDb(),
      where: 'id_petak = ?',
      whereArgs: [petak.idPetak],
    );
    return petak.idPetak!;
  }

  Future<List<Petak>> semuaPetak() async {
    final db = await database;
    final rows = await db.query('petak', orderBy: 'nama COLLATE NOCASE');
    return rows.map(Petak.fromDb).toList();
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

  // ------------------------------------------------------------------ berkas

  /// Menyalin foto hasil kamera/galeri ke folder aplikasi agar tetap
  /// tersedia walau cache galeri dibersihkan.
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
