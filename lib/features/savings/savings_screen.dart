import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/insforge_service.dart';
import '../../widgets/ui.dart';

class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});
  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  List<SavingsEntry> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = InsforgeService.client.auth.currentUser?.id;
    if (uid == null) return;
    final items = await ref.read(financeRepositoryProvider).listSavings(uid);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final total = _items.fold<double>(0, (s, e) => s + e.amount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: gradientAppBar('Savings'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add savings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 96),
              children: [
                SurfaceCard(
                  gradient: AppGradients.brand,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Total saved', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(Money.format(total), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.6)),
                          const SizedBox(height: 6),
                          Text('Across ${_items.length} deposit${_items.length == 1 ? '' : 's'}',
                              style: const TextStyle(fontSize: 11, color: Colors.white70)),
                        ]),
                      ),
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(18)),
                        child: const Icon(Icons.savings_rounded, color: Colors.white, size: 26),
                      ),
                    ],
                  ),
                ),
                const SectionHeader('Deposits', padding: EdgeInsets.fromLTRB(4, 18, 4, 6)),
                if (_items.isEmpty)
                  EmptyState(
                    icon: Icons.savings_outlined,
                    title: 'No savings logged',
                    message: 'Log transfers to your savings or emergency fund to keep the streak visible.',
                    actionLabel: 'Add savings',
                    onAction: () => _add(context),
                  )
                else
                  ..._items.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SurfaceCard(
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            leading: const SoftIcon(Icons.savings_outlined, color: AppColors.primary, size: 40, radius: 13),
                            title: Text(Money.format(e.amount), style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text('${_date(e.entryDate)}${e.description?.isNotEmpty == true ? ' • ${e.description}' : ''}'),
                          ),
                        ),
                      )),
              ],
            ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add savings'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Amount (₹)'), keyboardType: TextInputType.number),
          const SizedBox(height: 10),
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Note (optional)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final uid = InsforgeService.client.auth.currentUser?.id;
              if (uid == null) return;
              await ref.read(financeRepositoryProvider).addSavings(
                    SavingsEntry(userId: uid, amount: double.tryParse(amountCtrl.text) ?? 0, entryDate: DateTime.now(), description: descCtrl.text),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
              _load();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
