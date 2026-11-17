import 'package:flutter/material.dart';

/// Token desain aplikasi.
///
/// Sumber: `design-system/padi-scan/MASTER.md`, dihasilkan dengan skill
/// `ui-ux-pro-max` (`--design-system`, gaya "Organic Biophilic", palet
/// "Earth green + harvest gold"). Seluruh layar WAJIB memakai token ini,
/// bukan nilai heksadesimal yang ditulis langsung di widget.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppRadius {
  static const double kecil = 12;
  static const double sedang = 16;
  static const double besar = 20;
  static const double pil = 999;
}

/// Durasi gerak bersama. Aturan desain: 150-300 ms, tidak satu durasi
/// untuk semua transisi.
abstract final class AppDurasi {
  static const Duration cepat = Duration(milliseconds: 150);
  static const Duration sedang = Duration(milliseconds: 200);
  static const Duration lambat = Duration(milliseconds: 300);
}

/// Ukuran ikon sebagai token, bukan nilai acak per layar.
abstract final class AppIkon {
  static const double kecil = 18;
  static const double sedang = 22;
  static const double besar = 24;
  static const double hero = 30;
}

/// Target sentuh minimum Android: 48 dp.
const double kTargetSentuh = 48;

/// Palet per tema, diambil dari `MASTER.md`.
@immutable
class AppPalet extends ThemeExtension<AppPalet> {
  const AppPalet({
    required this.primary,
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

  /// Warna status. Tema terang dan gelap memakai nilai berbeda agar
  /// kontras teks tetap di atas 4,5:1 pada kedua mode.
  final Color success;
  final Color warning;

  /// Palet terang — "soft sage on warm paper".
  ///
  /// Menggantikan palet hijau pekat sebelumnya atas permintaan pengguna:
  /// hijau dijadikan sage yang diredam, latar diubah dari hijau mint ke
  /// krem netral hangat. Semua pasangan teks tetap >= 4,5:1 (dijaga
  /// `test/tema_test.dart`).
  static const terang = AppPalet(
    primary: Color(0xFF4F7157),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF7A9578),
    onSecondary: Color(0xFF1E2A22),
    accent: Color(0xFFA8834A),
    onAccent: Color(0xFF2A1F0E),
    background: Color(0xFFF7F5F0),
    foreground: Color(0xFF2C3A30),
    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF2C3A30),
    muted: Color(0xFFEDEAE3),
    mutedForeground: Color(0xFF5E6B60),
    border: Color(0xFFDCD8CE),
    destructive: Color(0xFFAA4A41),
    onDestructive: Color(0xFFFFFFFF),
    success: Color(0xFF4F7157),
    warning: Color(0xFF8A6A38),
  );

  /// Palet gelap — "sage on warm charcoal".
  ///
  /// Latar tidak lagi hijau-hitam, melainkan arang hangat netral. Hijau
  /// diterangkan secukupnya agar kontras di atas latar gelap tetap
  /// memenuhi 4,5:1 (tidak boleh disalin apa adanya dari palet terang).
  static const gelap = AppPalet(
    primary: Color(0xFF9DBFA3),
    onPrimary: Color(0xFF1A2B1F),
    secondary: Color(0xFF7E9B84),
    onSecondary: Color(0xFF16231A),
    accent: Color(0xFFD9B87C),
    onAccent: Color(0xFF2A1F0E),
    background: Color(0xFF1A1C19),
    foreground: Color(0xFFE8E6DF),
    card: Color(0xFF242723),
    cardForeground: Color(0xFFE8E6DF),
    muted: Color(0xFF2E322C),
    mutedForeground: Color(0xFFA9B3A8),
    border: Color(0xFF3A3E38),
    destructive: Color(0xFFE08A80),
    onDestructive: Color(0xFF3A1410),
    success: Color(0xFF9DBFA3),
    warning: Color(0xFFD9B87C),
  );

  @override
  AppPalet copyWith({
    Color? primary,
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

/// Pintasan akses palet dari konteks.
extension PaletKonteks on BuildContext {
  AppPalet get palet => Theme.of(this).extension<AppPalet>()!;
  TextTheme get teks => Theme.of(this).textTheme;
  ColorScheme get skema => Theme.of(this).colorScheme;

  /// Warna status untuk sebuah tingkat keyakinan (F-04).
  ///
  /// Ambang mengikuti aturan R5: di bawah 70% berarti tidak dikenali.
  Color warnaKeyakinan(double persen) {
    if (persen >= 85) return palet.success;
    if (persen >= 70) return palet.warning;
    return palet.destructive;
  }
}
