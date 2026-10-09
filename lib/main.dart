import 'package:flutter/material.dart';

import 'core/app_store.dart';
import 'screens/home_shell.dart';
import 'ui/qrex_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final store = await AppStore.load();
    runApp(QrexApp(store: store));
  } catch (_) {
    // Do not crash at launch if the device's settings storage is unavailable.
    runApp(const QrexStorageRecovery());
  }
}

class QrexApp extends StatelessWidget {
  const QrexApp({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) => MaterialApp(
      title: 'QREX',
      debugShowCheckedModeBanner: false,
      theme: qrexTheme(store.light),
      home: QrexStartup(store: store),
    ),
  );
}

/// A local recovery screen if OS storage fails during initialization.
class QrexStorageRecovery extends StatefulWidget {
  const QrexStorageRecovery({super.key});

  @override
  State<QrexStorageRecovery> createState() => _QrexStorageRecoveryState();
}

class _QrexStorageRecoveryState extends State<QrexStorageRecovery> {
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      final store = await AppStore.load();
      if (!mounted) {
        store.dispose();
        return;
      }
      runApp(QrexApp(store: store));
    } catch (_) {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: qrexTheme(false),
    home: Scaffold(body: SafeArea(child: Center(child: Padding(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 410),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const QrexMark(size: 82),
          const SizedBox(height: 28),
          const Icon(Icons.storage_outlined, color: QrexPalette.cyan, size: 36),
          const SizedBox(height: 16),
          const Text('Podaci uređaja trenutačno nisu dostupni.',
            textAlign: TextAlign.center, style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const Text('Provjeri slobodan prostor na uređaju pa pokušaj ponovno. '
              'Tvoji postojeći kodovi neće biti automatski obrisani.',
            textAlign: TextAlign.center),
          const SizedBox(height: 22),
          QrexButton(label: _retrying ? 'Pokušavam…' : 'Pokušaj ponovno',
            onPressed: _retrying ? null : _retry),
        ]),
      ),
    )))),
  );
}

/// A brief brand introduction with no login, onboarding or network request.
class QrexStartup extends StatefulWidget {
  const QrexStartup({super.key, required this.store});
  final AppStore store;

  @override
  State<QrexStartup> createState() => _QrexStartupState();
}

class _QrexStartupState extends State<QrexStartup> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return HomeShell(store: widget.store);
    return Scaffold(body: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF030C1B), Color(0xFF091F47), Color(0xFF160B3A)],
      )),
      child: SafeArea(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const QrexMark(size: 102),
          const SizedBox(height: 23),
          const QrexWordmark(),
          const SizedBox(height: 8),
          const Text('Skeniraj. Stvori. Dijeli.',
            style: TextStyle(color: Color(0xFFD2E2FB), fontSize: 16, letterSpacing: .4)),
          const SizedBox(height: 38),
          const SizedBox(width: 34, height: 3,
            child: LinearProgressIndicator(
              color: QrexPalette.cyan,
              backgroundColor: QrexPalette.surfaceBright,
            )),
        ],
      )),
    ));
  }
}
