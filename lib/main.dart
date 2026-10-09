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
      home: HomeShell(store: store),
    ),
  );
}
