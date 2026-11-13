import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/insforge_service.dart';
import '../../widgets/ui.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});
  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  List<FinancialGoal> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = InsforgeService.client.auth.currentUser?.id;
    if (uid == null) return;
    final items = await ref.read(financeRepositoryProvider).listGoals(uid);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  String _label(String type) => switch (type) {
        'emergency_fund' => 'Emergency fund',
        'education' => 'Education',
        'house' => 'House',
        'vehicle' => 'Vehicle',
        'retirement' => 'Retirement',
        _ => 'Custom goal',
      };

  IconData _icon(String type) => switch (type) {
        'emergency_fund' => Icons.health_and_safety_outlined,
        'education' => Icons.school_outlined,
        'house' => Icons.home_outlined,
        'vehicle' => Icons.directions_car_outlined,
        'retirement' => Icons.beach_access_outlined,
        _ => Icons.flag_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final target = _items.fold<double>(0, (s, g) => s + g.targetAmount);
    final saved = _items.fold<double>(0, (s, g) => s + g.currentAmount);
    final overall = target > 0 ? (saved / target).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: gradientAppBar('Goals', automaticallyImplyLeading: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New goal'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 96),
              children: [
                if (_items.isNotEmpty) ...[
                  SurfaceCard(
                    gradient: AppGradients.header,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Total progress', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('${Money.format(saved)} of ${Money.format(target)}',
                          style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: overall,
                          minHeight: 8,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('${(overall * 100).toStringAsFixed(0)}% of all goals funded • ${_items.length} active',
                          style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
                    ]),
                  ),
                  const SectionHeader('Your goals', padding: EdgeInsets.fromLTRB(4, 18, 4, 6)),
                ],
                if (_items.isEmpty)
                  EmptyState(
                    icon: Icons.flag_outlined,
                    title: 'No goals yet',
                    message: 'Set a target — an emergency fund, a trip or a down payment — and watch your progress build.',
                    actionLabel: 'Create a goal',
                    onAction: () => _add(context),
                  )
                else
                  ..._items.map((g) {
                    final pct = (g.progress * 100).toStringAsFixed(0);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SurfaceCard(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            SoftIcon(_icon(g.goalType), color: AppColors.primary, size: 42, radius: 14),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                                const SizedBox(height: 2),
                                Text('${_label(g.goalType)} • ${g.status}', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                              ]),
                            ),
                            Text('$pct%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary)),
                          ]),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: g.progress,
                              minHeight: 7,
                              backgroundColor: AppColors.primarySoft,
                              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Row(children: [
                            Expanded(
                              child: Text('${Money.format(g.currentAmount)} saved',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                            ),
                            Text('Target ${Money.format(g.targetAmount)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ]),
                          if (g.monthlyContribution > 0) ...[
                            const SizedBox(height: 4),
                            Text('Adding ${Money.format(g.monthlyContribution)} every month',
                                style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                          ],
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
    final targetCtrl = TextEditingController();
    final contribCtrl = TextEditingController();
    String type = 'emergency_fund';
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New goal'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Goal name')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: type,
              items: ['emergency_fund', 'education', 'house', 'vehicle', 'retirement', 'custom']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' '))))
                  .toList(),
              onChanged: (v) => type = v ?? type,
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 10),
            TextField(controller: targetCtrl, decoration: const InputDecoration(labelText: 'Target amount (₹)'), keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            TextField(controller: contribCtrl, decoration: const InputDecoration(labelText: 'Monthly contribution (₹)'), keyboardType: TextInputType.number),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final uid = InsforgeService.client.auth.currentUser?.id;
              if (uid == null) return;
              await ref.read(financeRepositoryProvider).addGoal(
                    FinancialGoal(
                      userId: uid,
                      name: nameCtrl.text.isEmpty ? 'Goal' : nameCtrl.text,
                      goalType: type,
                      targetAmount: double.tryParse(targetCtrl.text) ?? 0,
                      monthlyContribution: double.tryParse(contribCtrl.text) ?? 0,
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
