import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/insforge_service.dart';
import '../../models/models.dart';
import '../../services/ml/forecast.dart';
import '../../core/utils/money.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';

class PredictionsScreen extends ConsumerStatefulWidget {
  const PredictionsScreen({super.key});
  @override
  ConsumerState<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends ConsumerState<PredictionsScreen> {
  List<Prediction> _items = [];
  bool _loading = true;
  bool _running = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final uid = InsforgeService.client.auth.currentUser?.id;
    if (uid == null) return;
    final items = await ref.read(financeRepositoryProvider).listPredictions(uid);
    setState(() { _items = items; _loading = false; });
  }

  Future<void> _run() async {
    setState(() => _running = true);
    final uid = InsforgeService.client.auth.currentUser?.id;
    if (uid == null) return;
    final repo = ref.read(financeRepositoryProvider);
    final profile = await repo.getProfile(uid);
    final expenses = await repo.listExpenses(uid);
    // Build monthly series
    final byMonth = <String, double>{};
    for (final e in expenses) {
      final key = '${e.entryDate.year}-${e.entryDate.month.toString().padLeft(2, '0')}';
      byMonth[key] = (byMonth[key] ?? 0) + e.amount;
    }
    final keys = byMonth.keys.toList()..sort();
    final series = keys.map((k) => byMonth[k]!).toList();
    final res = MlForecast.forecast(series, horizon: 6, cityTier: profile?.cityTier ?? 'Tier 2');
    final pred = Prediction(
      userId: uid,
      modelType: res.modelType,
      modelVersion: res.modelVersion,
      target: 'expense',
      horizonMonths: 6,
      values: res.values,
      confidence: res.confidence,
      validationMetric: res.validationMetric,
      trainedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
    await repo.savePrediction(pred);
    await _load();
    setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gradientAppBar('Predictions (ML)'),
      floatingActionButton: FloatingActionButton.extended(onPressed: _running ? null : _run, label: _running ? const Text('Running...') : const Text('Run Forecast'), icon: const Icon(Icons.play_arrow)),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_items.isEmpty) const Text('No predictions yet. Tap Run Forecast.'),
          ..._items.map((p) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Model: ${p.modelType} (${p.modelVersion})'),
            Text('Confidence: ${p.confidence}'),
            if (p.validationMetric != null) Text('Validation error: ${p.validationMetric!.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            ...p.values.asMap().entries.map((e) => Text('Month ${e.key + 1}: ${Money.format(e.value)}')),
          ])))),
        ],
      ),
    );
  }
}
