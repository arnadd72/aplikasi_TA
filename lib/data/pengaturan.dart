import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Penyimpanan pengaturan lokal berbasis berkas JSON (PRD F-01, F-15, F-25).
///
/// Menyimpan:
/// - `mode_tema`: Terang / Gelap / Ikuti sistem
/// - `onboarding_selesai`: status penyelesaian onboarding (F-01)
/// - `bookmark_penyakit`: daftar ID penyakit yang disimpan pengguna (F-25)
class PengaturanStore {
  PengaturanStore._();
  static final PengaturanStore instance = PengaturanStore._();

  static const String _namaBerkas = 'pengaturan.json';

  final ValueNotifier<ThemeMode> modeTema = ValueNotifier<ThemeMode>(
    ThemeMode.system,
  );

  final ValueNotifier<bool> onboardingSelesai = ValueNotifier<bool>(false);

  final ValueNotifier<Set<String>> bookmarkPenyakit =
      ValueNotifier<Set<String>>(<String>{});

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
      onboardingSelesai.value = (mentah['onboarding_selesai'] as bool?) ?? false;
      final markah = mentah['bookmark_penyakit'];
      if (markah is List) {
        bookmarkPenyakit.value = {
          for (final item in markah)
            if (item is String && item.isNotEmpty) item,
        };
      }
    } on Object catch (e) {
      debugPrint('[Pengaturan] gagal memuat: $e');
    }
  }

  Future<void> simpanModeTema(ThemeMode mode) async {
    modeTema.value = mode;
    _tulisTanpaTunggu();
  }

  Future<void> simpanOnboardingSelesai(bool selesai) async {
    onboardingSelesai.value = selesai;
    _tulisTanpaTunggu();
  }

  Future<void> toggleBookmarkPenyakit(String idPenyakit) async {
    final salinan = Set<String>.from(bookmarkPenyakit.value);
    if (!salinan.remove(idPenyakit)) {
      salinan.add(idPenyakit);
    }
    bookmarkPenyakit.value = salinan;
    _tulisTanpaTunggu();
  }

  bool apakahDisimpan(String idPenyakit) =>
      bookmarkPenyakit.value.contains(idPenyakit);

  void _tulisTanpaTunggu() {
    _tulis().ignore();
  }

  Future<void> _tulis() async {
    try {
      final berkas = await _berkas();
      final kode = switch (modeTema.value) {
        ThemeMode.light => 'terang',
        ThemeMode.dark => 'gelap',
        ThemeMode.system => 'sistem',
      };
      await berkas.writeAsString(
        jsonEncode({
          'mode_tema': kode,
          'onboarding_selesai': onboardingSelesai.value,
          'bookmark_penyakit': bookmarkPenyakit.value.toList()..sort(),
        }),
      );
    } on Object catch (e) {
      debugPrint('[Pengaturan] gagal menyimpan: $e');
    }
  }

  static String labelMode(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'Terang',
    ThemeMode.dark => 'Gelap',
    ThemeMode.system => 'Ikuti sistem',
  };
}
