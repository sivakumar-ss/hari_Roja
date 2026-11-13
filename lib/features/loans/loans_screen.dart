import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/insforge_service.dart';
import '../../widgets/ui.dart';

class LoansScreen extends ConsumerStatefulWidget {
  const LoansScreen({super.key});
  @override
  ConsumerState<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends ConsumerState<LoansScreen> {
  List<Loan> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = InsforgeService.client.auth.currentUser?.id;
    if (uid == null) return;
    final items = await ref.read(financeRepositoryProvider).listLoans(uid);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final outstanding = _items.fold<double>(0, (s, l) => s + l.outstanding);
    final emi = _items.fold<double>(0, (s, l) => s + l.emi);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: gradientAppBar('Loans & EMI'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add loan'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 96),
              children: [
                Row(children: [
                  Expanded(
                    child: SurfaceCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const SoftIcon(Icons.account_balance_outlined, color: AppColors.danger, size: 36, radius: 12),
                        const SizedBox(height: 10),
                        const Text('Outstanding', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                        Text(Money.format(outstanding), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SurfaceCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const SoftIcon(Icons.event_repeat_rounded, color: AppColors.warning, size: 36, radius: 12),
                        const SizedBox(height: 10),
                        const Text('Monthly EMI', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                        Text(Money.format(emi), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      ]),
                    ),
                  ),
                ]),
                const SectionHeader('Your loans', padding: EdgeInsets.fromLTRB(4, 18, 4, 6)),
                if (_items.isEmpty)
                  EmptyState(
                    icon: Icons.account_balance_outlined,
                    title: 'No loans added',
                    message: 'Add a loan to see how its EMI affects your risk score and savings plan.',
                    actionLabel: 'Add loan',
                    onAction: () => _add(context),
                  )
                else
                  ..._items.map((l) {
                    final paid = l.principal > 0 ? (1 - l.outstanding / l.principal).clamp(0.0, 1.0) : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SurfaceCard(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            const SoftIcon(Icons.account_balance_outlined, color: AppColors.primary, size: 40, radius: 13),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(l.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text('${Money.format(l.outstanding)} left • EMI ${Money.format(l.emi)}',
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                              ]),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline_rounded, size: 20),
                              onPressed: () async {
                                await ref.read(financeRepositoryProvider).deleteLoan(l.id!);
                                _load();
                              },
                            ),
                          ]),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: paid,
                              minHeight: 6,
                              backgroundColor: AppColors.primarySoft,
                              valueColor: const AlwaysStoppedAnimation(AppColors.success),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text('${(paid * 100).toStringAsFixed(0)}% repaid • ${l.interestRate}% interest • ${l.tenureMonths} months',
                              style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                        ]),
                      ),
                    );
                  }),
              ],
            ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final principalCtrl = TextEditingController();
    final outstandingCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final tenureCtrl = TextEditingController();
    final emiCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add loan'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Loan name')),
            const SizedBox(height: 10),
            TextField(controller: principalCtrl, decoration: const InputDecoration(labelText: 'Principal'), keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            TextField(controller: outstandingCtrl, decoration: const InputDecoration(labelText: 'Outstanding'), keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            TextField(controller: rateCtrl, decoration: const InputDecoration(labelText: 'Interest rate %'), keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            TextField(controller: tenureCtrl, decoration: const InputDecoration(labelText: 'Tenure (months)'), keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            TextField(controller: emiCtrl, decoration: const InputDecoration(labelText: 'EMI'), keyboardType: TextInputType.number),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final uid = InsforgeService.client.auth.currentUser?.id;
              if (uid == null) return;
              final loan = Loan(
                userId: uid,
                name: nameCtrl.text.isEmpty ? 'Loan' : nameCtrl.text,
                principal: double.tryParse(principalCtrl.text) ?? 0,
                outstanding: double.tryParse(outstandingCtrl.text) ?? 0,
                interestRate: double.tryParse(rateCtrl.text) ?? 0,
                tenureMonths: int.tryParse(tenureCtrl.text) ?? 12,
                emi: double.tryParse(emiCtrl.text) ?? 0,
              );
              await ref.read(financeRepositoryProvider).addLoan(loan);
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
