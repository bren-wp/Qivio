import 'package:flutter/material.dart';

import '../core/app_store.dart';
import '../ui/qrex_theme.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key, required this.store, required this.navigate});
  final AppStore store;
  final void Function(int, {bool gallery}) navigate;

  Future<void> _confirmDelete(BuildContext context) async {
    final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Obrisati sve kodove?'),
      content: const Text('Ovo će trajno ukloniti povijest i spremljene kodove s uređaja.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Odustani')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Obriši sve')),
      ],
    ));
    if (yes == true) await store.clearAll();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: store, builder: (context, _) =>
      SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(18, 22, 18, 22), children: [
        Text('Više', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('Sve na jednom mjestu.', style: TextStyle(color: QrexPalette.muted)),
        const SizedBox(height: 22),
        Card(child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 19),
          decoration: BoxDecoration(gradient: QrexPalette.bluePurple,
            borderRadius: BorderRadius.circular(18)),
          child: const Row(children: [
            QrexMark(size: 42), SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Skeniraj. Stvori. Dijeli.',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
              SizedBox(height: 5),
              Text('Sve što trebaš za QR, bez prijave.',
                style: TextStyle(color: Colors.white, fontSize: 12)),
            ])),
          ]),
        )),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, childAspectRatio: 1.6,
          mainAxisSpacing: 12, crossAxisSpacing: 12,
          children: [
            _action(context, Icons.qr_code_scanner_rounded, 'Skeniraj', () => navigate(0)),
            _action(context, Icons.add_circle_outline_rounded, 'Stvori QR', () => navigate(1)),
            _action(context, Icons.history, 'Povijest', () => navigate(2)),
            _action(context, Icons.image_outlined, 'Skeniraj iz slike', () => navigate(0, gallery: true)),
          ],
        ),
        const SizedBox(height: 26),
        Text('Postavke', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(child: Column(children: [
          SwitchListTile(
            secondary: const Icon(Icons.light_mode_outlined, color: QrexPalette.primary),
            title: const Text('Svijetli izgled'),
            value: store.light,
            onChanged: store.setLight,
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.history_toggle_off, color: QrexPalette.primary),
            title: const Text('Spremanje povijesti'),
            subtitle: const Text('Skeniranja ostaju na uređaju.'),
            value: store.historyEnabled,
            onChanged: store.setHistoryEnabled,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            title: const Text('Izbriši sve podatke'),
            onTap: () => _confirmDelete(context),
          ),
        ])),
        const SizedBox(height: 20),
        Text('Privatnost', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Card(child: Padding(padding: EdgeInsets.all(18), child:
          Text('QREX ne traži prijavu, ne šalje tvoje QR kodove na naš poslužitelj i ne prati skeniranja. '
            'Povijest je spremljena na ovom uređaju i možeš je izbrisati u svakom trenutku. '
            'Vanjske poveznice mogu otvoriti internetske stranice i druge aplikacije.',
            style: TextStyle(height: 1.5)))),
        const SizedBox(height: 20),
        const Center(child: QrexWordmark()),
        const SizedBox(height: 5),
        const Center(child: Text('Verzija 0.1.1', style: TextStyle(color: QrexPalette.muted))),
      ])),
    );
  }

  Widget _action(BuildContext context, IconData icon, String label, VoidCallback onTap) =>
    Card(clipBehavior: Clip.antiAlias, child: InkWell(onTap: onTap, child:
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 29, color: QrexPalette.primary),
        const SizedBox(height: 10),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    ));
}
