import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Tema aplikasi.
///
/// Gaya "Organic Biophilic" dan palet "Earth green + harvest gold" berasal
/// dari `design-system/padi-scan/MASTER.md` (dihasilkan dengan skill
/// `ui-ux-pro-max`). Tipografi memakai Plus Jakarta Sans; lihat
/// `design-system/padi-scan/OVERRIDES.md` untuk alasan penggantian pasangan
/// font bawaan MASTER.md.
///
/// NF-04: tipografi dibuat besar dengan kontras tinggi agar mudah dibaca di
/// lahan terbuka. Setiap mode menyediakan palet sendiri sehingga kontras
/// teks dijaga minimal 4,5:1 pada tema terang maupun gelap.
abstract final class AppTheme {
  static const String keluargaFont = 'PlusJakartaSans';

  static ThemeData get terang => _bangun(AppPalet.terang, Brightness.light);
  static ThemeData get gelap => _bangun(AppPalet.gelap, Brightness.dark);

  static ThemeData _bangun(AppPalet p, Brightness kecerahan) {
    final terang = kecerahan == Brightness.light;

    final skema = ColorScheme(
      brightness: kecerahan,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: terang
          ? const Color(0xFFE3EAE1)
          : const Color(0xFF31402F),
      onPrimaryContainer: terang
          ? const Color(0xFF22301F)
          : const Color(0xFFE3EAE1),
      secondary: p.secondary,
      onSecondary: p.onSecondary,
      secondaryContainer: terang
          ? const Color(0xFFE9EDE6)
          : const Color(0xFF2E322C),
      onSecondaryContainer: terang
          ? const Color(0xFF22301F)
          : const Color(0xFFE3EAE1),
      tertiary: p.accent,
      onTertiary: p.onAccent,
      tertiaryContainer: terang
          ? const Color(0xFFF4EADA)
          : const Color(0xFF3B3222),
      onTertiaryContainer: terang
          ? const Color(0xFF2A1F0E)
          : const Color(0xFFF4EADA),
      error: p.destructive,
      onError: p.onDestructive,
      errorContainer: terang
          ? const Color(0xFFF6E3E1)
          : const Color(0xFF4A2420),
      onErrorContainer: terang
          ? const Color(0xFF3A1410)
          : const Color(0xFFF6E3E1),
      surface: p.background,
      onSurface: p.foreground,
      surfaceContainerLowest: p.card,
      surfaceContainerLow: terang
          ? const Color(0xFFFCFAF6)
          : const Color(0xFF1E211D),
      surfaceContainer: terang
          ? const Color(0xFFF2EFE8)
          : const Color(0xFF242723),
      surfaceContainerHigh: terang
          ? const Color(0xFFECE8E0)
          : const Color(0xFF2A2E28),
      surfaceContainerHighest: p.muted,
      onSurfaceVariant: p.mutedForeground,
      outline: p.border,
      outlineVariant: terang
          ? const Color(0xFFE5E1D8)
          : const Color(0xFF2E322C),
      inverseSurface: terang
          ? const Color(0xFF2C3A30)
          : const Color(0xFFE8E6DF),
      onInverseSurface: terang
          ? const Color(0xFFF7F5F0)
          : const Color(0xFF1A1C19),
      shadow: const Color(0xFF1A1C19),
      scrim: const Color(0xFF12140F),
    );

    final dasar = ThemeData(
      useMaterial3: true,
      brightness: kecerahan,
      colorScheme: skema,
      fontFamily: keluargaFont,
      scaffoldBackgroundColor: p.background,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    return dasar.copyWith(
      extensions: <ThemeExtension<dynamic>>[p],
      textTheme: _teks(dasar.textTheme, p),

      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.foreground,
        centerTitle: false,
        scrolledUnderElevation: 0,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: keluargaFont,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: p.foreground,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: p.foreground, size: AppIkon.besar),
        actionsIconTheme: IconThemeData(
          color: p.foreground,
          size: AppIkon.besar,
        ),
      ),

      cardTheme: CardThemeData(
        color: p.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.besar),
          side: BorderSide(color: p.border),
        ),
      ),

      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          disabledBackgroundColor: p.muted,
          disabledForegroundColor: p.mutedForeground,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          textStyle: const TextStyle(
            fontFamily: keluargaFont,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sedang),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          side: BorderSide(color: p.border, width: 1.5),
          textStyle: const TextStyle(
            fontFamily: keluargaFont,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sedang),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          minimumSize: const Size(kTargetSentuh, kTargetSentuh),
          textStyle: const TextStyle(
            fontFamily: keluargaFont,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.kecil),
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: p.foreground,
          minimumSize: const Size(kTargetSentuh, kTargetSentuh),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: p.muted,
        selectedColor: p.primary,
        labelStyle: TextStyle(
          fontFamily: keluargaFont,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: p.cardForeground,
        ),
        side: BorderSide(color: p.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pil),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.muted,
        circularTrackColor: p.muted,
        linearMinHeight: 10,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.besar),
          side: BorderSide(color: p.border),
        ),
        titleTextStyle: TextStyle(
          fontFamily: keluargaFont,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: p.cardForeground,
        ),
        contentTextStyle: TextStyle(
          fontFamily: keluargaFont,
          fontSize: 15,
          height: 1.5,
          color: p.mutedForeground,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: terang
            ? const Color(0xFF2C3A30)
            : const Color(0xFFE8E6DF),
        contentTextStyle: TextStyle(
          fontFamily: keluargaFont,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: terang ? const Color(0xFFF7F5F0) : const Color(0xFF1A1C19),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.kecil),
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: p.primary,
        textColor: p.foreground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.kecil),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.besar),
          ),
        ),
      ),
    );
  }

  /// Skala tipe. Ukuran badan tidak pernah di bawah 15 karena pembacaan
  /// dilakukan di luar ruangan dengan cahaya matahari.
  static TextTheme _teks(TextTheme dasar, AppPalet p) {
    return dasar.copyWith(
      displaySmall: TextStyle(
        fontSize: 34,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: p.foreground,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: p.foreground,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: p.foreground,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: p.foreground,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        height: 1.4,
        fontWeight: FontWeight.w700,
        color: p.cardForeground,
      ),
      titleSmall: TextStyle(
        fontSize: 15,
        height: 1.4,
        fontWeight: FontWeight.w700,
        color: p.cardForeground,
      ),
      bodyLarge: TextStyle(
        fontSize: 17,
        height: 1.55,
        fontWeight: FontWeight.w400,
        color: p.foreground,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        height: 1.55,
        fontWeight: FontWeight.w400,
        color: p.cardForeground,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: p.mutedForeground,
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: p.cardForeground,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: p.mutedForeground,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: p.mutedForeground,
      ),
    );
  }
}
