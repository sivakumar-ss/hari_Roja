import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/insforge_service.dart';
import '../../widgets/ui.dart';

class IncomeScreen extends ConsumerStatefulWidget {
  const IncomeScreen({super.key});
  @override
  ConsumerState<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends ConsumerState<IncomeScreen> {
  List<IncomeEntry> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = InsforgeService.client.auth.currentUser?.id;
    if (uid == null) return;
    final items = await ref.read(financeRepositoryProvider).listIncome(uid);
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
    final total = _items.fold<double>(0, (s, e) => s + e.amount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: gradientAppBar('Income'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add income'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 96),
              children: [
                SurfaceCard(
                  child: Row(
                    children: [
                      const SoftIcon(Icons.account_balance_wallet_outlined, color: AppColors.success, size: 46),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('This month', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                          Text(Money.format(monthTotal), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
                        ]),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        const Text('All time', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        Text(Money.format(total), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                      ]),
                    ],
                  ),
                ),
                const SectionHeader('History', padding: EdgeInsets.fromLTRB(4, 18, 4, 6)),
                if (_items.isEmpty)
                  EmptyState(
                    icon: Icons.savings_outlined,
                    title: 'No income yet',
                    message: 'Add your salary or any other income so your score and advice become accurate.',
                    actionLabel: 'Add income',
                    onAction: () => _add(context),
                  )
                else
                  ..._items.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SurfaceCard(
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            leading: const SoftIcon(Icons.south_west_rounded, color: AppColors.success, size: 40, radius: 13),
                            title: Text(Money.format(e.amount), style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text('${e.category} • ${_date(e.entryDate)}${e.description?.isNotEmpty == true ? ' • ${e.description}' : ''}'),
                            trailing: IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline_rounded, size: 20),
                              onPressed: () async {
                                await ref.read(financeRepositoryProvider).deleteIncome(e.id!);
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
    final catCtrl = TextEditingController(text: 'Salary');
    final descCtrl = TextEditingController();
    final date = DateTime.now();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add income'),
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
              final entry = IncomeEntry(
                userId: uid,
                amount: double.tryParse(amountCtrl.text) ?? 0,
                category: catCtrl.text.isEmpty ? 'Other' : catCtrl.text,
                entryDate: date,
                description: descCtrl.text,
              );
              await ref.read(financeRepositoryProvider).addIncome(entry);
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
