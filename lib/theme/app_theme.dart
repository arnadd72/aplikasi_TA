import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Tema aplikasi — konsep "Clean Agricultural Utility" (PRD Bagian 4.2 & 9.1).
///
/// Prinsip visual:
/// 1. Modern, fungsional, fokus keterbacaan di luar ruangan.
/// 2. Tidak ada gradien neon, glassmorphism, atau bayangan tebal.
/// 3. Skala tipografi mengikuti PRD Bagian 9.1 (26/22/18/16/14/12-13sp).
/// 4. Tinggi tombol utama 54 dp (rentang 52–56 dp), radius tombol 12 dp,
///    radius kartu 16 dp, target sentuh minimal 48 x 48 dp.
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
          ? const Color(0xFFDCE9BD)
          : const Color(0xFF1F4235),
      onPrimaryContainer: terang
          ? const Color(0xFF123D32)
          : const Color(0xFFDCE9BD),
      secondary: p.secondary,
      onSecondary: p.onSecondary,
      secondaryContainer: terang
          ? const Color(0xFFE6EFEA)
          : const Color(0xFF23322B),
      onSecondaryContainer: terang
          ? const Color(0xFF123D32)
          : const Color(0xFFE9EFEA),
      tertiary: p.accent,
      onTertiary: p.onAccent,
      tertiaryContainer: terang
          ? const Color(0xFFDCE9BD)
          : const Color(0xFF2B3B24),
      onTertiaryContainer: terang
          ? const Color(0xFF123D32)
          : const Color(0xFFDCE9BD),
      error: p.destructive,
      onError: p.onDestructive,
      errorContainer: terang
          ? const Color(0xFFFEE4E2)
          : const Color(0xFF4B1612),
      onErrorContainer: terang
          ? const Color(0xFF55110B)
          : const Color(0xFFFEE4E2),
      surface: p.background,
      onSurface: p.foreground,
      surfaceContainerLowest: p.card,
      surfaceContainerLow: terang
          ? const Color(0xFFFBFCFA)
          : const Color(0xFF161E1A),
      surfaceContainer: terang
          ? const Color(0xFFF2F5EF)
          : const Color(0xFF1B231F),
      surfaceContainerHigh: terang
          ? const Color(0xFFEAEEE7)
          : const Color(0xFF202A25),
      surfaceContainerHighest: p.muted,
      onSurfaceVariant: p.mutedForeground,
      outline: p.border,
      outlineVariant: terang
          ? const Color(0xFFE6ECE5)
          : const Color(0xFF27332C),
      inverseSurface: terang
          ? const Color(0xFF123D32)
          : const Color(0xFFE9EFEA),
      onInverseSurface: terang
          ? const Color(0xFFF7F8F4)
          : const Color(0xFF121815),
      shadow: const Color(0xFF121815),
      scrim: const Color(0xFF0B0F0D),
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
        foregroundColor: p.primaryDark,
        centerTitle: false,
        scrolledUnderElevation: 0,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: keluargaFont,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: p.primaryDark,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: p.primaryDark, size: AppIkon.besar),
        actionsIconTheme: IconThemeData(
          color: p.primaryDark,
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
          borderRadius: BorderRadius.circular(AppRadius.sedang),
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
          minimumSize: const Size.fromHeight(kTinggiTombolUtama),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.horizontal),
          textStyle: const TextStyle(
            fontFamily: keluargaFont,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.kecil),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          backgroundColor: p.card,
          minimumSize: const Size.fromHeight(kTinggiTombolUtama),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.horizontal),
          side: BorderSide(color: p.border, width: 1.5),
          textStyle: const TextStyle(
            fontFamily: keluargaFont,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.kecil),
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
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.kecil),
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: p.primaryDark,
          minimumSize: const Size(kTargetSentuh, kTargetSentuh),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.accent,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final aktif = states.contains(WidgetState.selected);
          return IconThemeData(
            color: aktif ? p.primaryDark : p.mutedForeground,
            size: AppIkon.besar,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final aktif = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: keluargaFont,
            fontSize: 12,
            fontWeight: aktif ? FontWeight.w600 : FontWeight.w500,
            color: aktif ? p.primaryDark : p.mutedForeground,
          );
        }),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: p.card,
        indicatorColor: p.accent,
        selectedIconTheme: IconThemeData(
          color: p.primaryDark,
          size: AppIkon.besar,
        ),
        unselectedIconTheme: IconThemeData(
          color: p.mutedForeground,
          size: AppIkon.besar,
        ),
        selectedLabelTextStyle: TextStyle(
          fontFamily: keluargaFont,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: p.primaryDark,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: keluargaFont,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: p.mutedForeground,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.kecil),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        labelStyle: TextStyle(
          fontFamily: keluargaFont,
          fontSize: 14,
          color: p.mutedForeground,
        ),
        hintStyle: TextStyle(
          fontFamily: keluargaFont,
          fontSize: 14,
          color: p.mutedForeground,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.kecil),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.kecil),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.kecil),
          borderSide: BorderSide(color: p.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.kecil),
          borderSide: BorderSide(color: p.destructive),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: p.card,
        selectedColor: p.accent,
        labelStyle: TextStyle(
          fontFamily: keluargaFont,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: p.cardForeground,
        ),
        side: BorderSide(color: p.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.kecil),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.muted,
        circularTrackColor: p.muted,
        linearMinHeight: 8,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sedang),
          side: BorderSide(color: p.border),
        ),
        titleTextStyle: TextStyle(
          fontFamily: keluargaFont,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: p.primaryDark,
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
            ? const Color(0xFF123D32)
            : const Color(0xFFE9EFEA),
        contentTextStyle: TextStyle(
          fontFamily: keluargaFont,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: terang
              ? const Color(0xFFF7F8F4)
              : const Color(0xFF121815),
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

      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: p.card,
        collapsedBackgroundColor: p.card,
        iconColor: p.primary,
        collapsedIconColor: p.mutedForeground,
        textColor: p.primaryDark,
        collapsedTextColor: p.foreground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sedang),
          side: BorderSide(color: p.border),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sedang),
          side: BorderSide(color: p.border),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sedang),
          ),
        ),
      ),
    );
  }

  /// Skala tipografi mengikuti PRD Bagian 9.1:
  /// - Heading utama:    26sp Semibold (w600)
  /// - Heading halaman:  22sp Semibold (w600)
  /// - Judul section:    18sp Semibold (w600)
  /// - Judul kartu:      16sp Semibold (w600)
  /// - Body:             16sp Regular  (w400)
  /// - Teks pendukung:   14sp Regular  (w400)
  /// - Caption:       12-13sp Medium   (w500)
  /// - Tombol utama:     16sp Semibold (w600)
  static TextTheme _teks(TextTheme dasar, AppPalet p) {
    return dasar.copyWith(
      displaySmall: TextStyle(
        fontSize: 26,
        height: 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: p.primaryDark,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        height: 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: p.primaryDark,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: p.primaryDark,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        height: 1.35,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: p.primaryDark,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: p.cardForeground,
      ),
      titleSmall: TextStyle(
        fontSize: 15,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: p.cardForeground,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: p.foreground,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: p.cardForeground,
      ),
      bodySmall: TextStyle(
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: p.mutedForeground,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: p.cardForeground,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        height: 1.35,
        fontWeight: FontWeight.w500,
        color: p.mutedForeground,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w500,
        color: p.mutedForeground,
      ),
    );
  }
}
