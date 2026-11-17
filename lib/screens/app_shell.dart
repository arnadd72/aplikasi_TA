import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'informasi_screen.dart';
import 'petak_screen.dart';
import 'riwayat_screen.dart';

/// Kerangka navigasi utama empat menu sesuai PRD Bagian 5.1:
/// 1. Beranda    — Ringkasan kondisi, pintasan identifikasi, aktivitas
/// 2. Lahan Saya — Pengelolaan lahan, catatan dan monitoring
/// 3. Riwayat    — Hasil identifikasi sebelumnya
/// 4. Panduan    — Informasi penyakit dan edukasi
///
/// Pengaturan diakses melalui ikon pada bagian atas Beranda (PRD Bagian 5.1).
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.halaman, this.indeksAwal = 0});

  final List<Widget>? halaman;
  final int indeksAwal;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _indeks;

  static const _tujuan = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Beranda',
    ),
    NavigationDestination(
      icon: Icon(Icons.grass_outlined),
      selectedIcon: Icon(Icons.grass_rounded),
      label: 'Lahan Saya',
    ),
    NavigationDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history_rounded),
      label: 'Riwayat',
    ),
    NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book_rounded),
      label: 'Panduan',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _indeks = widget.indeksAwal.clamp(0, 3);
  }

  void _pindahTab(int indeksBaru) {
    if (!mounted) return;
    setState(() => _indeks = indeksBaru.clamp(0, 3));
  }

  @override
  Widget build(BuildContext context) {
    final halaman =
        widget.halaman ??
        [
          HomeScreen(onPindahTab: _pindahTab),
          const PetakScreen(),
          RiwayatScreen(onMulaiIdentifikasi: () => _pindahTab(0)),
          const InformasiScreen(),
        ];
    assert(halaman.length == 4);

    return LayoutBuilder(
      builder: (context, batas) {
        final lebar = batas.maxWidth >= 840;
        final isi = IndexedStack(index: _indeks, children: halaman);
        if (lebar) {
          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    selectedIndex: _indeks,
                    onDestinationSelected: _pindahTab,
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final tujuan in _tujuan)
                        NavigationRailDestination(
                          icon: tujuan.icon,
                          selectedIcon: tujuan.selectedIcon,
                          label: Text(tujuan.label),
                        ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: isi),
              ],
            ),
          );
        }
        return Scaffold(
          body: isi,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _indeks,
            onDestinationSelected: _pindahTab,
            destinations: _tujuan,
          ),
        );
      },
    );
  }
}
