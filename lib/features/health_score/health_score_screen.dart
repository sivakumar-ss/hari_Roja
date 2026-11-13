import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/insforge_service.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';

class HealthScoreScreen extends ConsumerStatefulWidget {
  const HealthScoreScreen({super.key});
  @override
  ConsumerState<HealthScoreScreen> createState() => _HealthScoreScreenState();
}

class _HealthScoreScreenState extends ConsumerState<HealthScoreScreen> {
  FinancialScore? _score;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final uid = InsforgeService.client.auth.currentUser?.id;
    if (uid == null) return;
    final s = await ref.read(financeRepositoryProvider).latestScore(uid);
    setState(() { _score = s; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gradientAppBar('Financial Health Score'),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Padding(
        padding: const EdgeInsets.all(16),
        child: _score == null ? const Text('No score yet. Visit dashboard.') : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Overall: ${_score!.overallScore.toStringAsFixed(1)} / 100', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _row('Savings', _score!.savingsScore),
          _row('Spending', _score!.spendingScore),
          _row('Debt', _score!.debtScore),
          _row('Emergency', _score!.emergencyScore),
          _row('Investment', _score!.investmentScore),
          _row('Retirement', _score!.retirementScore),
        ]),
      ),
    );
  }

  Widget _row(String label, double v) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Expanded(child: Text(label)), Text(v.toStringAsFixed(1))]));
}
