import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/insforge_service.dart';
import '../../widgets/ui.dart';

class ExpenseScreen extends ConsumerStatefulWidget {
  const ExpenseScreen({super.key});
  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  List<ExpenseEntry> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = InsforgeService.client.auth.currentUser?.id;
    if (uid == null) return;
    final items = await ref.read(financeRepositoryProvider).listExpenses(uid);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthTotal = _items.where((e) => e.entryDate.year == now.year && e.entryDate.month == now.month).fold<double>(0, (s, e) => s + e.amount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: gradientAppBar('Expenses'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add expense'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 96),
              children: [
                SurfaceCard(
                  child: Row(
                    children: [
                      const SoftIcon(Icons.north_east_rounded, color: AppColors.danger, size: 46),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Spent this month', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                          Text(Money.format(monthTotal), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
                        ]),
                      ),
                      InfoPill(icon: Icons.receipt_long_outlined, label: '${_items.length} entries', color: AppColors.danger),
                    ],
                  ),
                ),
                const SectionHeader('History', padding: EdgeInsets.fromLTRB(4, 18, 4, 6)),
                if (_items.isEmpty)
                  EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No expenses yet',
                    message: 'Track what you spend to see where your money actually goes each month.',
                    actionLabel: 'Add expense',
                    onAction: () => _add(context),
                  )
                else
                  ..._items.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SurfaceCard(
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            leading: const SoftIcon(Icons.north_east_rounded, color: AppColors.danger, size: 40, radius: 13),
                            title: Text(Money.format(e.amount), style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text('${e.category} • ${_date(e.entryDate)}${e.description?.isNotEmpty == true ? ' • ${e.description}' : ''}'),
                            trailing: IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline_rounded, size: 20),
                              onPressed: () async {
                                await ref.read(financeRepositoryProvider).deleteExpense(e.id!);
                                _load();
                              },
                            ),
                          ),
                        ),
                      )),
              ],
            ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final amountCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'Food');
    final descCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add expense'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Amount (₹)'), keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Category')),
            const SizedBox(height: 10),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (optional)')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final uid = InsforgeService.client.auth.currentUser?.id;
              if (uid == null) return;
              final entry = ExpenseEntry(
                userId: uid,
                amount: double.tryParse(amountCtrl.text) ?? 0,
                category: catCtrl.text.isEmpty ? 'Other' : catCtrl.text,
                entryDate: DateTime.now(),
                description: descCtrl.text,
              );
              await ref.read(financeRepositoryProvider).addExpense(entry);
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
