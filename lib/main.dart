import 'package:flutter/material.dart';

import 'data/pengaturan.dart';
import 'screens/app_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PengaturanStore.instance.muat();
  runApp(const PadiScanApp(tampilkanSplashSaatMulai: true));
}

/// Akar aplikasi Padi Scan — "Modern Agricultural Utility" (PRD v1.0).
class PadiScanApp extends StatelessWidget {
  const PadiScanApp({
    super.key,
    this.tampilkanOnboardingBilaBelum = true,
    this.tampilkanSplashSaatMulai = false,
  });

  final bool tampilkanOnboardingBilaBelum;
  final bool tampilkanSplashSaatMulai;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: PengaturanStore.instance.modeTema,
      builder: (context, mode, _) => ValueListenableBuilder<bool>(
        valueListenable: PengaturanStore.instance.onboardingSelesai,
        builder: (context, sudahOnboarding, _) => MaterialApp(
          title: 'Padi Scan',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.terang,
          darkTheme: AppTheme.gelap,
          themeMode: mode,
          home: tampilkanSplashSaatMulai
              ? const SplashScreen()
              : (!tampilkanOnboardingBilaBelum || sudahOnboarding)
              ? const AppShell()
              : const OnboardingScreen(),
        ),
      ),
    );
  }
}
