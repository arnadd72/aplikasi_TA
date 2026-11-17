import 'package:flutter/material.dart';

import 'data/pengaturan.dart';
import 'screens/app_shell.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Pengaturan dibaca sekali di awal agar pilihan tema pengguna langsung
  // berlaku saat aplikasi dibuka.
  await PengaturanStore.instance.muat();
  runApp(const PadiScanApp());
}

/// Akar aplikasi.
///
/// Tema mengikuti pengaturan pengguna; bawaannya mengikuti sistem. Kedua
/// palet diuji terpisah; lihat `lib/theme/app_tokens.dart`.
class PadiScanApp extends StatelessWidget {
  const PadiScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: PengaturanStore.instance.modeTema,
      builder: (context, mode, _) => MaterialApp(
        title: 'Padi Scan',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.terang,
        darkTheme: AppTheme.gelap,
        themeMode: mode,
        home: const AppShell(),
      ),
    );
  }
}
