import 'package:flutter/material.dart';

import '../core/app_store.dart';
import '../ui/qrex_theme.dart';
import 'create_page.dart';
import 'history_page.dart';
import 'more_page.dart';
import 'scanner_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.store});
  final AppStore store;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _page = 0;
  bool _gallery = false;

  void _select(int index, {bool gallery = false}) {
    setState(() {
      _page = index;
      _gallery = gallery;
    });
  }

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    final pages = <Widget>[
      ScannerPage(key: ValueKey('scanner-$_gallery'), store: widget.store, openGalleryInitially: _gallery),
      CreatePage(store: widget.store),
      HistoryPage(store: widget.store),
      MorePage(store: widget.store, navigate: _select),
    ];
    return Scaffold(
      backgroundColor: light ? const Color(0xFFF3F6FF) : QrexPalette.base,
      body: pages[_page],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: light ? Colors.white : const Color(0xFF071225),
          border: Border(top: BorderSide(color: light ? Colors.black12 : Colors.white12)),
        ),
        child: SafeArea(top: false, child: NavigationBar(
          height: 70,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          indicatorColor: QrexPalette.primary.withValues(alpha: .20),
          selectedIndex: _page,
          onDestinationSelected: (i) => _select(i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.qr_code_scanner_outlined), selectedIcon: Icon(Icons.qr_code_scanner), label: 'Skeniraj'),
            NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Stvori'),
            NavigationDestination(icon: Icon(Icons.history), selectedIcon: Icon(Icons.history), label: 'Povijest'),
            NavigationDestination(icon: Icon(Icons.grid_view_rounded), selectedIcon: Icon(Icons.grid_view_rounded), label: 'Više'),
          ],
        )),
      ),
    );
  }
}
