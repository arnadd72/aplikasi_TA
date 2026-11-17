import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Penyimpanan pengaturan sederhana berbasis berkas JSON.
///
/// Sengaja tidak memakai paket tambahan agar aplikasi tetap ringan dan
/// seluruh proses berjalan luring (NF-01). Berkas disimpan di direktori
/// dokumen aplikasi bersama foto hasil identifikasi.
class PengaturanStore {
  PengaturanStore._();
  static final PengaturanStore instance = PengaturanStore._();

  static const String _namaBerkas = 'pengaturan.json';

  /// Mode tema yang dipilih pengguna. Dibaca `PadiScanApp` sehingga
  /// perubahan langsung berlaku tanpa membuka ulang aplikasi.
  final ValueNotifier<ThemeMode> modeTema = ValueNotifier<ThemeMode>(
    ThemeMode.system,
  );

  bool _sudahDimuat = false;

  Future<File> _berkas() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _namaBerkas));
  }

  /// Memuat pengaturan tersimpan. Aman dipanggil berkali-kali.
  Future<void> muat() async {
    if (_sudahDimuat) return;
    _sudahDimuat = true;
    try {
      final berkas = await _berkas();
      if (!await berkas.exists()) return;
      final mentah = jsonDecode(await berkas.readAsString());
      if (mentah is! Map<String, dynamic>) return;
      final kode = mentah['mode_tema'];
      modeTema.value = switch (kode) {
        'terang' => ThemeMode.light,
        'gelap' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } on Object catch (e) {
      debugPrint('[Pengaturan] gagal memuat: $e');
    }
  }

  Future<void> simpanModeTema(ThemeMode mode) async {
    modeTema.value = mode;
    await _tulis();
  }

  Future<void> _tulis() async {
    try {
      final berkas = await _berkas();
      final kode = switch (modeTema.value) {
        ThemeMode.light => 'terang',
        ThemeMode.dark => 'gelap',
        ThemeMode.system => 'sistem',
      };
      await berkas.writeAsString(jsonEncode({'mode_tema': kode}));
    } on Object catch (e) {
      debugPrint('[Pengaturan] gagal menyimpan: $e');
    }
  }

  /// Label mode tema untuk ditampilkan di layar pengaturan.
  static String labelMode(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'Terang',
    ThemeMode.dark => 'Gelap',
    ThemeMode.system => 'Ikuti sistem',
  };
}
