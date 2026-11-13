import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/insforge_service.dart';
import '../../models/models.dart';
import '../../services/risk_engine.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';

class RiskScreen extends ConsumerStatefulWidget {
  const RiskScreen({super.key});
  @override
  ConsumerState<RiskScreen> createState() => _RiskScreenState();
}

class _RiskScreenState extends ConsumerState<RiskScreen> {
  FinancialRisk? _risk;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final uid = InsforgeService.client.auth.currentUser?.id;
    if (uid == null) return;
    final r = await ref.read(financeRepositoryProvider).latestRisk(uid);
    setState(() { _risk = r; _loading = false; });
  }

  Future<void> _recompute() async {
    final uid = InsforgeService.client.auth.currentUser?.id;
    if (uid == null) return;
    final repo = ref.read(financeRepositoryProvider);
    final profile = await repo.getProfile(uid);
    final incomes = await repo.listIncome(uid);
    final expenses = await repo.listExpenses(uid);
    final savings = await repo.listSavings(uid);
    final loans = await repo.listLoans(uid);
    final investments = await repo.listInvestments(uid);
    final now = DateTime.now();
    final mi = incomes.where((e)=>e.entryDate.year==now.year && e.entryDate.month==now.month).fold<double>(0,(s,e)=>s+e.amount);
    final me = expenses.where((e)=>e.entryDate.year==now.year && e.entryDate.month==now.month).fold<double>(0,(s,e)=>s+e.amount);
    final res = RiskEngine.compute(
      monthlyIncome: mi == 0 ? (profile?.monthlyIncome ?? 0) : mi,
      monthlyExpense: me,
      currentSavings: savings.fold<double>(0,(s,e)=>s+e.amount),
      totalDebt: loans.fold<double>(0,(s,l)=>s+l.outstanding),
      monthlyEmi: loans.fold<double>(0,(s,l)=>s+l.emi),
      investmentTotal: investments.fold<double>(0,(s,i)=>s+i.amount),
    );
    await repo.saveRisk(FinancialRisk(userId: uid, riskLevel: res['level'] as String, factors: (res['factors'] as List).cast<String>(), computedAt: DateTime.now()));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gradientAppBar('Risk Assessment'),
      floatingActionButton: FloatingActionButton(onPressed: _recompute, child: const Icon(Icons.refresh)),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Overall Risk: ${_risk?.riskLevel ?? '-'}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Contributing factors:'),
          ...(_risk?.factors ?? []).map((f) => Text('• $f')),
        ]),
      ),
    );
  }
}
