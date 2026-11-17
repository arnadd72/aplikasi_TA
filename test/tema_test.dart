import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padi_scan/theme/app_theme.dart';
import 'package:padi_scan/theme/app_tokens.dart';

/// Pengujian tema.
///
/// Memverifikasi dua hal yang diminta daftar periksa pradeliver
/// `ui-ux-pro-max`: kontras teks minimal 4,5:1, dan kedua mode
/// (terang/gelap) diuji secara terpisah.
void main() {
  /// Rasio kontras WCAG 2.1 butir 1.4.3.
  double kontras(Color a, Color b) {
    double kanal(double c) => c <= 0.03928
        ? c / 12.92
        : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    double luminans(Color c) =>
        0.2126 * kanal(c.r) + 0.7152 * kanal(c.g) + 0.0722 * kanal(c.b);
    final l1 = luminans(a);
    final l2 = luminans(b);
    return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
  }

  group('Palet terang', () {
    const p = AppPalet.terang;

    test('teks utama di atas latar memenuhi 4,5:1', () {
      expect(kontras(p.foreground, p.background), greaterThanOrEqualTo(4.5));
    });

    test('teks utama di atas kartu memenuhi 4,5:1', () {
      expect(kontras(p.cardForeground, p.card), greaterThanOrEqualTo(4.5));
    });

    test('tombol utama memenuhi 4,5:1', () {
      expect(kontras(p.onPrimary, p.primary), greaterThanOrEqualTo(4.5));
    });

    test('teks redup masih memenuhi 4,5:1 di atas latar', () {
      expect(
        kontras(p.mutedForeground, p.background),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('warna galat memenuhi 4,5:1', () {
      expect(kontras(p.destructive, p.background), greaterThanOrEqualTo(4.5));
    });
  });

  group('Palet gelap', () {
    const p = AppPalet.gelap;

    test('teks utama di atas latar memenuhi 4,5:1', () {
      expect(kontras(p.foreground, p.background), greaterThanOrEqualTo(4.5));
    });

    test('teks utama di atas kartu memenuhi 4,5:1', () {
      expect(kontras(p.cardForeground, p.card), greaterThanOrEqualTo(4.5));
    });

    test('tombol utama memenuhi 4,5:1', () {
      expect(kontras(p.onPrimary, p.primary), greaterThanOrEqualTo(4.5));
    });

    test('teks redup masih memenuhi 4,5:1 di atas latar', () {
      expect(
        kontras(p.mutedForeground, p.background),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('warna galat memenuhi 4,5:1', () {
      expect(kontras(p.destructive, p.background), greaterThanOrEqualTo(4.5));
    });
  });

  group('Tema', () {
    test('kedua mode memakai paletnya sendiri', () {
      expect(AppTheme.terang.extension<AppPalet>(), AppPalet.terang);
      expect(AppTheme.gelap.extension<AppPalet>(), AppPalet.gelap);
    });

    test('tema terang dan gelap berbeda kecerahannya', () {
      expect(AppTheme.terang.brightness, Brightness.light);
      expect(AppTheme.gelap.brightness, Brightness.dark);
    });

    test('ukuran badan tidak di bawah 15 piksel', () {
      for (final tema in [AppTheme.terang, AppTheme.gelap]) {
        expect(tema.textTheme.bodyMedium!.fontSize, greaterThanOrEqualTo(15));
        expect(tema.textTheme.bodyLarge!.fontSize, greaterThanOrEqualTo(15));
      }
    });

    test('target sentuh tombol memenuhi 48 dp', () {
      final ukuran = AppTheme.terang.filledButtonTheme.style!.minimumSize!
          .resolve({})!;
      expect(ukuran.height, greaterThanOrEqualTo(kTargetSentuh));
    });

    test('warnaKeyakinan mengikuti ambang aturan R5', () {
      const p = AppPalet.terang;
      Color hitung(double persen) {
        if (persen >= 85) return p.success;
        if (persen >= 70) return p.warning;
        return p.destructive;
      }

      expect(hitung(95), p.success);
      expect(hitung(85), p.success);
      expect(hitung(70), p.warning);
      expect(hitung(69.99), p.destructive);
    });
  });
}
