import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';
import '../../models/models.dart';
import '../../models/profile.dart';
import '../../providers/providers.dart';
import '../../services/alert_engine.dart';
import '../../services/insforge_service.dart';
import '../../services/recommendation_engine.dart';
import '../../services/risk_engine.dart';
import '../../services/score_engine.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/ui.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _loading = true;
  Profile? _profile;
  List<IncomeEntry> _incomes = [];
  List<ExpenseEntry> _expenses = [];
  List<SavingsEntry> _savings = [];
  List<Loan> _loans = [];
  List<Investment> _investments = [];
  List<FinancialGoal> _goals = [];
  FinancialScore? _score;
  FinancialRisk? _risk;
  List<Alert> _alerts = [];
  List<Recommendation> _recs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final uid = InsforgeService.client.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    final repo = ref.read(financeRepositoryProvider);
    try {
      _profile = await repo.getProfile(uid);
      _incomes = await repo.listIncome(uid);
      _expenses = await repo.listExpenses(uid);
      _savings = await repo.listSavings(uid);
      _loans = await repo.listLoans(uid);
      _investments = await repo.listInvestments(uid);
      _goals = await repo.listGoals(uid);
      _score = await repo.latestScore(uid);
      _risk = await repo.latestRisk(uid);
      _alerts = await repo.listAlerts(uid);
      _recs = await repo.listRecommendations(uid);

      final now = DateTime.now();
      final monthlyIncome = _incomes.where((e) => e.entryDate.year == now.year && e.entryDate.month == now.month).fold<double>(0, (s, e) => s + e.amount);
      final monthlyExpense = _expenses.where((e) => e.entryDate.year == now.year && e.entryDate.month == now.month).fold<double>(0, (s, e) => s + e.amount);
      final currentSavings = _savings.fold<double>(0, (s, e) => s + e.amount);
      final totalDebt = _loans.fold<double>(0, (s, l) => s + l.outstanding);
      final monthlyEmi = _loans.fold<double>(0, (s, l) => s + l.emi);
      final investmentTotal = _investments.fold<double>(0, (s, i) => s + i.amount);
      final mi = monthlyIncome == 0 ? (_profile?.monthlyIncome ?? 0) : monthlyIncome;

      if (_score == null) {
        final comp = ScoreEngine.compute(
          monthlyIncome: mi,
          monthlyExpense: monthlyExpense,
          currentSavings: currentSavings,
          totalDebtOutstanding: totalDebt,
          monthlyEmi: monthlyEmi,
          investmentTotal: investmentTotal,
          age: _profile?.age ?? 30,
          emergencyFundTarget: monthlyExpense * 6,
        );
        final fs = FinancialScore(
          userId: uid,
          overallScore: comp['overall']!,
          savingsScore: comp['savings']!,
          spendingScore: comp['spending']!,
          debtScore: comp['debt']!,
          emergencyScore: comp['emergency']!,
          investmentScore: comp['investment']!,
          retirementScore: comp['retirement']!,
          computedAt: now,
        );
        await repo.saveScore(fs);
        _score = fs;
      }
      if (_risk == null) {
        final r = RiskEngine.compute(
          monthlyIncome: mi,
          monthlyExpense: monthlyExpense,
          currentSavings: currentSavings,
          totalDebt: totalDebt,
          monthlyEmi: monthlyEmi,
          investmentTotal: investmentTotal,
        );
        final fr = FinancialRisk(userId: uid, riskLevel: r['level'] as String, factors: (r['factors'] as List).cast<String>(), computedAt: now);
        await repo.saveRisk(fr);
        _risk = fr;
      }
      if (_alerts.isEmpty) {
        final newAlerts = AlertEngine.evaluate(
          userId: uid,
          monthlyIncome: mi,
          monthlyExpense: monthlyExpense,
          savings: mi - monthlyExpense,
          currentSavings: currentSavings,
          monthlyEmi: monthlyEmi,
          goals: _goals,
        );
        for (final a in newAlerts) {
          await repo.addAlert(a);
        }
        _alerts = await repo.listAlerts(uid);
      }
      if (_recs.isEmpty) {
        final newRecs = RecommendationEngine.generate(
          userId: uid,
          monthlyIncome: mi,
          monthlyExpense: monthlyExpense,
          currentSavings: currentSavings,
          totalDebt: totalDebt,
          monthlyEmi: monthlyEmi,
          investmentTotal: investmentTotal,
          goals: _goals,
        );
        for (final r in newRecs) {
          await repo.addRecommendation(r);
        }
        _recs = await repo.listRecommendations(uid);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final now = DateTime.now();
    final monthlyIncome = _incomes.where((e) => e.entryDate.year == now.year && e.entryDate.month == now.month).fold<double>(0, (s, e) => s + e.amount);
    final monthlyExpense = _expenses.where((e) => e.entryDate.year == now.year && e.entryDate.month == now.month).fold<double>(0, (s, e) => s + e.amount);
    final surplus = monthlyIncome - monthlyExpense;
    final totalSavings = _savings.fold<double>(0, (s, e) => s + e.amount);
    final mi = monthlyIncome == 0 ? (_profile?.monthlyIncome ?? 0) : monthlyIncome;
    final savingsRate = mi > 0 ? (surplus / mi * 100) : 0.0;
    final rawName = _profile?.fullName?.trim();
    final name = (rawName != null && rawName.isNotEmpty) ? rawName : (InsforgeService.client.auth.currentUser?.name ?? 'there');
    final firstName = name.split(' ').first;
    final unread = _alerts.where((a) => !a.isRead && !a.isDismissed).length;
    final isNewUser = _incomes.isEmpty && _expenses.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 168,
              backgroundColor: AppColors.primaryDark,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              foregroundColor: Colors.white,
              title: Row(children: [
                const AppLogo(size: 26, showText: false),
                const SizedBox(width: 9),
                Text('Finance Advisor', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 15, fontWeight: FontWeight.w700)),
              ]),
              actions: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      tooltip: 'Alerts',
                      onPressed: () => context.push('/alerts'),
                      icon: const Icon(Icons.notifications_none_rounded),
                    ),
                    if (unread > 0)
                      Positioned(
                        right: 8,
                        top: 9,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          constraints: const BoxConstraints(minWidth: 16),
                          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white, width: 1.2)),
                          child: Text('$unread', textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12, left: 2),
                  child: GestureDetector(
                    onTap: () => context.go('/settings'),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.18), border: Border.all(color: Colors.white.withValues(alpha: 0.5))),
                      child: Center(
                        child: Text(
                          firstName.isNotEmpty ? firstName.substring(0, 1).toUpperCase() : 'U',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 20),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hi, $firstName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4, height: 1.0)),
                    const SizedBox(height: 2),
                    Text(
                      isNewUser ? 'Let\'s set up your money picture' : '${_weekday(now)}, ${now.day} ${_month(now)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 10.5, fontWeight: FontWeight.w500, height: 1.0),
                    ),
                  ],
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    const DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.header)),
                    Positioned(top: -70, right: -50, child: _blob(210, Colors.white.withValues(alpha: 0.08))),
                    Positioned(bottom: -40, left: -60, child: _blob(180, Colors.white.withValues(alpha: 0.05))),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isNewUser) ...[_gettingStarted(), const SizedBox(height: 16)],
                    _scoreCard(),
                    const SizedBox(height: 6),
                    _statsGrid(monthlyIncome, monthlyExpense, surplus, totalSavings, savingsRate),
                    const SectionHeader('Quick actions', padding: EdgeInsets.fromLTRB(6, 20, 6, 8)),
                    _quickActions(),
                    const SectionHeader('Explore', padding: EdgeInsets.fromLTRB(6, 22, 6, 8)),
                    _explore(),
                    if (_goals.isNotEmpty) ...[
                      SectionHeader('Your goals', actionLabel: 'See all', onActionTap: () => context.go('/goals'), padding: const EdgeInsets.fromLTRB(6, 22, 6, 8)),
                      _goalsCard(),
                    ],
                    if (_alerts.where((a) => !a.isDismissed).isNotEmpty) ...[
                      SectionHeader('Recent alerts', actionLabel: 'View all', onActionTap: () => context.push('/alerts'), padding: const EdgeInsets.fromLTRB(6, 22, 6, 8)),
                      _alertsCard(),
                    ],
                    if (_recs.isNotEmpty) ...[
                      SectionHeader('Smart suggestions', actionLabel: 'View all', onActionTap: () => context.push('/recommendations'), padding: const EdgeInsets.fromLTRB(6, 22, 6, 8)),
                      _recsCard(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  String _weekday(DateTime d) => const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][d.weekday - 1];
  String _month(DateTime d) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1];

  Widget _gettingStarted() {
    return SurfaceCard(
      gradient: AppGradients.soft,
      child: Row(
        children: [
          const SoftIcon(Icons.auto_awesome_rounded, color: AppColors.violet, size: 46),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Start with one number', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                SizedBox(height: 3),
                Text('Add your income and an expense to unlock your score.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => context.push('/income'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  Widget _scoreCard() {
    final score = _score?.overallScore ?? 0;
    final risk = _risk?.riskLevel;
    final riskColor = risk == 'HIGH' ? const Color(0xFFFFB4AB) : risk == 'MEDIUM' ? const Color(0xFFFFD666) : const Color(0xFF8CF5C8);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppGradients.header,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [BoxShadow(color: Color(0x334F46E5), blurRadius: 30, offset: Offset(0, 14))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                    value: (score / 100).clamp(0, 1),
                    strokeWidth: 9,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(score.toStringAsFixed(0), style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
                    Text('/100', style: TextStyle(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.75))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Expanded(
                    child: Text('Financial health', style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700)),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/health'),
                    child: Row(children: [
                      Text('Details', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11.5, fontWeight: FontWeight.w600)),
                      Icon(Icons.chevron_right_rounded, size: 16, color: Colors.white.withValues(alpha: 0.9)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 8),
                if (risk != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 7, height: 7, decoration: BoxDecoration(color: riskColor, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('$risk risk', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                const SizedBox(height: 10),
                Text('Total savings', style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 11)),
                const SizedBox(height: 2),
                Text(Money.format(_savings.fold<double>(0, (s, e) => s + e.amount)),
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid(double income, double expense, double surplus, double totalSavings, double savingsRate) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.72,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _statTile('Income', Money.format(income), Icons.south_west_rounded, AppColors.success, 'This month'),
        _statTile('Expenses', Money.format(expense), Icons.north_east_rounded, AppColors.danger, 'This month'),
        _statTile('Left to save', Money.format(surplus), Icons.savings_outlined, AppColors.primary, 'Income − expenses'),
        _statTile('Savings rate', '${savingsRate.toStringAsFixed(1)}%', Icons.percent_rounded, AppColors.accentDark, 'Balance ${Money.format(totalSavings)}'),
      ],
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color, String caption) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            SoftIcon(icon, color: color, size: 30, radius: 10),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ),
          ]),
          const Spacer(),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.3)),
          const SizedBox(height: 1),
          Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _quickActions() {
    final actions = <List<Object>>[
      ['Add income', Icons.add_circle_outline_rounded, AppColors.success, '/income'],
      ['Add expense', Icons.remove_circle_outline_rounded, AppColors.danger, '/expenses'],
      ['Goals', Icons.flag_outlined, AppColors.accentDark, '/goals'],
      ['Ask AI', Icons.auto_awesome_outlined, AppColors.violet, '/chatbot'],
      ['Predictions', Icons.insights_rounded, AppColors.primary, '/predictions'],
      ['Loans', Icons.account_balance_outlined, AppColors.textSecondary, '/loans'],
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.12,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: actions.map((a) {
        final label = a[0] as String;
        final icon = a[1] as IconData;
        final color = a[2] as Color;
        final route = a[3] as String;
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => route == '/goals' || route == '/chatbot' ? context.go(route) : context.push(route),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SoftIcon(icon, color: color, size: 42, radius: 14),
                const SizedBox(height: 9),
                Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _explore() {
    final items = <List<Object>>[
      ['Savings', Icons.savings_outlined, '/savings'],
      ['Investments', Icons.trending_up_rounded, '/investments'],
      ['Schemes', Icons.account_balance_rounded, '/schemes'],
      ['Risk', Icons.shield_outlined, '/risk'],
      ['Inflation', Icons.show_chart_rounded, '/inflation'],
      ['Patterns', Icons.donut_small_outlined, '/patterns'],
      ['Health score', Icons.favorite_outline_rounded, '/health'],
      ['Voice', Icons.mic_none_rounded, '/voice'],
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((i) {
        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => context.push(i[2] as String),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(i[1] as IconData, size: 15, color: AppColors.primary),
              const SizedBox(width: 7),
              Text(i[0] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _goalsCard() {
    return SurfaceCard(
      child: Column(
        children: _goals.take(3).map((g) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ),
                  Text('${(g.progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12.5)),
                ]),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: g.progress,
                    minHeight: 7,
                    backgroundColor: AppColors.primarySoft,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 5),
                Text('${Money.format(g.currentAmount)} of ${Money.format(g.targetAmount)}',
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _alertsCard() {
    final visible = _alerts.where((a) => !a.isDismissed).take(3).toList();
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: visible.map((a) {
          final critical = a.severity == 'critical';
          return ListTile(
            leading: SoftIcon(
              critical ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
              color: critical ? AppColors.danger : AppColors.warning,
              size: 38,
              radius: 12,
            ),
            title: Text(a.title),
            subtitle: Text(a.message, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              tooltip: 'Dismiss',
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () async {
                await ref.read(financeRepositoryProvider).dismissAlert(a.id!);
                _load();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _recsCard() {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: _recs.take(3).map((r) {
          return ListTile(
            leading: const SoftIcon(Icons.lightbulb_outline_rounded, color: AppColors.accentDark, size: 38, radius: 12),
            title: Text(r.title),
            subtitle: Text(r.reason, maxLines: 2, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
      ),
    );
  }
}
