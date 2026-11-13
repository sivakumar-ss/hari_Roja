import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/insforge_service.dart';
import '../../widgets/ui.dart';

class InvestmentsScreen extends ConsumerStatefulWidget {
  const InvestmentsScreen({super.key});
  @override
  ConsumerState<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends ConsumerState<InvestmentsScreen> {
  List<Investment> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = InsforgeService.client.auth.currentUser?.id;
    if (uid == null) return;
    final items = await ref.read(financeRepositoryProvider).listInvestments(uid);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final total = _items.fold<double>(0, (s, i) => s + i.amount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: gradientAppBar('Investments'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add investment'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 96),
              children: [
                SurfaceCard(
                  child: Row(children: [
                    const SoftIcon(Icons.trending_up_rounded, color: AppColors.success, size: 46),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Portfolio value', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                        Text(Money.format(total), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
                      ]),
                    ),
                    InfoPill(icon: Icons.pie_chart_outline_rounded, label: '${_items.length} assets', color: AppColors.success),
                  ]),
                ),
                const SectionHeader('Holdings', padding: EdgeInsets.fromLTRB(4, 18, 4, 6)),
                if (_items.isEmpty)
                  EmptyState(
                    icon: Icons.trending_up_rounded,
                    title: 'No investments yet',
                    message: 'Add mutual funds, SIPs or stocks to complete your financial picture.',
                    actionLabel: 'Add investment',
                    onAction: () => _add(context),
                  )
                else
                  ..._items.map((inv) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SurfaceCard(
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            leading: const SoftIcon(Icons.trending_up_rounded, color: AppColors.success, size: 40, radius: 13),
                            title: Text(inv.name?.isNotEmpty == true ? inv.name! : inv.type, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text('${inv.type} • ${_date(inv.investedOn)}'),
                            trailing: Text(Money.format(inv.amount),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.textPrimary)),
                          ),
                        ),
                      )),
              ],
            ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final typeCtrl = TextEditingController(text: 'Mutual Fund');
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add investment'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Type')),
            const SizedBox(height: 10),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name (optional)')),
            const SizedBox(height: 10),
            TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Amount (₹)'), keyboardType: TextInputType.number),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final uid = InsforgeService.client.auth.currentUser?.id;
              if (uid == null) return;
              await ref.read(financeRepositoryProvider).addInvestment(
                    Investment(
                      userId: uid,
                      type: typeCtrl.text.isEmpty ? 'Other' : typeCtrl.text,
                      name: nameCtrl.text.isEmpty ? null : nameCtrl.text,
                      amount: double.tryParse(amountCtrl.text) ?? 0,
                      investedOn: DateTime.now(),
                    ),
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
