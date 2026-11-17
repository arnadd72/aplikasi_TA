import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'informasi_screen.dart';
import 'pengaturan_screen.dart';
import 'riwayat_screen.dart';

/// Kerangka navigasi utama. IndexedStack mempertahankan posisi/keadaan tab.
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
      icon: Icon(Icons.document_scanner_outlined),
      selectedIcon: Icon(Icons.document_scanner),
      label: 'Periksa',
    ),
    NavigationDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history),
      label: 'Riwayat',
    ),
    NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book),
      label: 'Edukasi',
    ),
    NavigationDestination(
      icon: Icon(Icons.tune_outlined),
      selectedIcon: Icon(Icons.tune),
      label: 'Pengaturan',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _indeks = widget.indeksAwal.clamp(0, 3);
  }

  @override
  Widget build(BuildContext context) {
    final halaman =
        widget.halaman ??
        const [
          HomeScreen(),
          RiwayatScreen(),
          InformasiScreen(),
          PengaturanScreen(),
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
                    onDestinationSelected: (nilai) =>
                        setState(() => _indeks = nilai),
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
            onDestinationSelected: (nilai) => setState(() => _indeks = nilai),
            destinations: _tujuan,
          ),
        );
      },
    );
  }
}
