import 'package:flutter/material.dart';

import '../core/app_store.dart';
import '../core/qr_payload.dart';
import '../ui/qrex_theme.dart';
import 'result_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.store});
  final AppStore store;
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _query = TextEditingController();
  bool _savedOnly = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _confirmClear() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obrisati povijest?'),
        content: const Text('Skeniranja će biti obrisana. Spremljeni kodovi ostaju.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Obriši')),
        ],
      ),
    );
    if (yes == true) await widget.store.clearHistory();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final query = _query.text.toLowerCase();
      final items = widget.store.entries.where((e) =>
          (!_savedOnly || e.saved) &&
          (e.title.toLowerCase().contains(query) || e.raw.toLowerCase().contains(query))).toList();
      return SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(18, 22, 18, 12), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('Povijest', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800))),
              if (widget.store.entries.any((e) => !e.saved))
                IconButton(tooltip: 'Obriši povijest', icon: const Icon(Icons.delete_sweep_outlined), onPressed: _confirmClear),
            ]),
            const SizedBox(height: 14),
            TextField(
              controller: _query, onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Pretraži kodove', prefixIcon: Icon(Icons.search_rounded)),
            ),
            const SizedBox(height: 10),
            Row(children: [
              FilterChip(label: const Text('Sve'), selected: !_savedOnly,
                onSelected: (_) => setState(() => _savedOnly = false)),
              const SizedBox(width: 8),
              FilterChip(label: const Text('Spremljeno'), selected: _savedOnly,
                onSelected: (_) => setState(() => _savedOnly = true)),
            ]),
          ])),
        Expanded(child: items.isEmpty
          ? const Center(child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.qr_code_rounded, size: 58, color: QrexPalette.muted),
              SizedBox(height: 14),
              Text('Nema kodova za prikaz.', textAlign: TextAlign.center),
            ]),
          ))
          : ListView.separated(
            padding: const EdgeInsets.fromLTRB(15, 4, 15, 22),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(child: ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: QrexPalette.primary.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(13)),
                  child: Icon(iconForKind(item.kind), color: QrexPalette.cyan),
                ),
                title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${item.kind.label} · ${_date(item.date)}', maxLines: 1),
                trailing: PopupMenuButton<String>(
                  tooltip: 'Radnje',
                  onSelected: (selection) async {
                    if (selection == 'save') await widget.store.save(item.raw);
                    if (selection == 'delete') await widget.store.remove(item);
                  },
                  itemBuilder: (context) => [
                    if (!item.saved) const PopupMenuItem(value: 'save', child: Text('Spremi')),
                    const PopupMenuItem(value: 'delete', child: Text('Obriši')),
                  ],
                  icon: const Icon(Icons.more_vert),
                ),
                onTap: () => Navigator.push<void>(context,
                  MaterialPageRoute(builder: (_) => ResultPage(store: widget.store, raw: item.raw))),
              ));
            },
          ),
        ),
      ]));
    },
  );

  String _date(DateTime d) => '${d.day}.${d.month}.${d.year}.  '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
