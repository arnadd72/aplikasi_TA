import 'package:flutter/material.dart';

/// Token desain aplikasi Padi Scan — "Modern Agricultural Utility".
///
/// Mengikuti spesifikasi PRD Bagian 9.1 (Clean Agricultural Utility):
/// - Padding horizontal: 20 dp
/// - Spacing kecil: 8 dp, sedang: 12–16 dp, section: 24 dp
/// - Radius kartu: 16 dp, radius tombol: 12 dp
/// - Tinggi tombol utama: 52–56 dp (54 dp)
/// - Target sentuh minimum: 48 x 48 dp
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double smPlus = 12;
  static const double md = 16;
  static const double horizontal = 20;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppRadius {
  /// Radius tombol sesuai PRD Bagian 9.1: 12 dp.
  static const double kecil = 12;

  /// Radius kartu sesuai PRD Bagian 9.1: 16 dp.
  static const double sedang = 16;

  /// Radius kartu utama sesuai PRD Bagian 9.1: 16 dp.
  static const double besar = 16;

  static const double pil = 999;
}

/// Durasi transisi fungsional (150-300 ms).
abstract final class AppDurasi {
  static const Duration cepat = Duration(milliseconds: 150);
  static const Duration sedang = Duration(milliseconds: 200);
  static const Duration lambat = Duration(milliseconds: 300);
}

/// Ukuran ikon garis sederhana yang konsisten.
abstract final class AppIkon {
  static const double kecil = 18;
  static const double sedang = 20;
  static const double besar = 24;
  static const double hero = 28;
}

/// Target sentuh minimum Android: 48 dp (PRD Bagian 9.1 & NFR-08).
const double kTargetSentuh = 48;

/// Tinggi tombol utama sesuai PRD Bagian 9.1: 52–56 dp.
const double kTinggiTombolUtama = 54;

/// Palet warna "Clean Agricultural Utility" (PRD Bagian 9.1).
@immutable
class AppPalet extends ThemeExtension<AppPalet> {
  const AppPalet({
    required this.primary,
    required this.primaryDark,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.accent,
    required this.onAccent,
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.muted,
    required this.mutedForeground,
    required this.border,
    required this.destructive,
    required this.onDestructive,
    required this.success,
    required this.warning,
  });

  final Color primary;
  final Color primaryDark;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color accent;
  final Color onAccent;
  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color muted;
  final Color mutedForeground;
  final Color border;
  final Color destructive;
  final Color onDestructive;
  final Color success;
  final Color warning;

  /// Palet terang persis mengikuti tabel PRD Bagian 9.1:
  /// - Primary:        #176B4D (Tombol dan aksi utama)
  /// - Primary Dark:   #123D32 (Heading penting dan elemen navigasi)
  /// - Background:     #F7F8F4 (Latar utama)
  /// - Surface / Card: #FFFFFF (Kartu dan komponen)
  /// - Border:         #E0E6DF (Batas elemen)
  /// - Text Primary:   #17251E (Teks utama)
  /// - Text Secondary: #627168 (Teks pendukung)
  /// - Warning:        #A76516 (Kondisi perlu perhatian)
  /// - Danger:         #B42318 (Kesalahan dan penghapusan)
  /// - Accent:         #DCE9BD (Penekanan ringan)
  static const terang = AppPalet(
    primary: Color(0xFF176B4D),
    primaryDark: Color(0xFF123D32),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF123D32),
    onSecondary: Color(0xFFFFFFFF),
    accent: Color(0xFFDCE9BD),
    onAccent: Color(0xFF123D32),
    background: Color(0xFFF7F8F4),
    foreground: Color(0xFF17251E),
    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF17251E),
    muted: Color(0xFFEEF1EC),
    mutedForeground: Color(0xFF56655C),
    border: Color(0xFFE0E6DF),
    destructive: Color(0xFFB42318),
    onDestructive: Color(0xFFFFFFFF),
    success: Color(0xFF176B4D),
    warning: Color(0xFFA76516),
  );

  /// Palet gelap pendamping "Clean Agricultural Utility" dengan kontras >= 4,5:1.
  static const gelap = AppPalet(
    primary: Color(0xFF6CC4A1),
    primaryDark: Color(0xFFBCE0CB),
    onPrimary: Color(0xFF0E2920),
    secondary: Color(0xFF88B8A2),
    onSecondary: Color(0xFF0E2920),
    accent: Color(0xFF2B3B24),
    onAccent: Color(0xFFDCE9BD),
    background: Color(0xFF121815),
    foreground: Color(0xFFE9EFEA),
    card: Color(0xFF1B231F),
    cardForeground: Color(0xFFE9EFEA),
    muted: Color(0xFF232D28),
    mutedForeground: Color(0xFFA3B2AA),
    border: Color(0xFF2E3B34),
    destructive: Color(0xFFF97066),
    onDestructive: Color(0xFF3B0A07),
    success: Color(0xFF6CC4A1),
    warning: Color(0xFFF3B359),
  );

  @override
  AppPalet copyWith({
    Color? primary,
    Color? primaryDark,
    Color? onPrimary,
    Color? secondary,
    Color? onSecondary,
    Color? accent,
    Color? onAccent,
    Color? background,
    Color? foreground,
    Color? card,
    Color? cardForeground,
    Color? muted,
    Color? mutedForeground,
    Color? border,
    Color? destructive,
    Color? onDestructive,
    Color? success,
    Color? warning,
  }) {
    return AppPalet(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      card: card ?? this.card,
      cardForeground: cardForeground ?? this.cardForeground,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      border: border ?? this.border,
      destructive: destructive ?? this.destructive,
      onDestructive: onDestructive ?? this.onDestructive,
      success: success ?? this.success,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppPalet lerp(ThemeExtension<AppPalet>? other, double t) {
    if (other is! AppPalet) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalet(
      primary: l(primary, other.primary),
      primaryDark: l(primaryDark, other.primaryDark),
      onPrimary: l(onPrimary, other.onPrimary),
      secondary: l(secondary, other.secondary),
      onSecondary: l(onSecondary, other.onSecondary),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      background: l(background, other.background),
      foreground: l(foreground, other.foreground),
      card: l(card, other.card),
      cardForeground: l(cardForeground, other.cardForeground),
      muted: l(muted, other.muted),
      mutedForeground: l(mutedForeground, other.mutedForeground),
      border: l(border, other.border),
      destructive: l(destructive, other.destructive),
      onDestructive: l(onDestructive, other.onDestructive),
      success: l(success, other.success),
      warning: l(warning, other.warning),
    );
  }
}

/// Pintasan akses palet dan tipografi dari konteks.
extension PaletKonteks on BuildContext {
  AppPalet get palet => Theme.of(this).extension<AppPalet>()!;
  TextTheme get teks => Theme.of(this).textTheme;
  ColorScheme get skema => Theme.of(this).colorScheme;

  /// Warna status tingkat keyakinan (PRD Bagian 6 F-06 & F-07).
  /// Ambang 70% mengikuti aturan R5.
  Color warnaKeyakinan(double persen) {
    if (persen >= 85) return palet.success;
    if (persen >= 70) return palet.warning;
    return palet.destructive;
  }
}
