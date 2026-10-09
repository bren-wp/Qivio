import 'package:flutter/material.dart';

import 'core/app_store.dart';
import 'screens/home_shell.dart';
import 'ui/qrex_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await AppStore.load();
  runApp(QrexApp(store: store));
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
    Future<void>.delayed(const Duration(milliseconds: 750), () {
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
