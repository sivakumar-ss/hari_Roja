import '../models/models.dart';

class RecommendationEngine {
  static List<Recommendation> generate({
    required String userId,
    required double monthlyIncome,
    required double monthlyExpense,
    required double currentSavings,
    required double totalDebt,
    required double monthlyEmi,
    required double investmentTotal,
    required List<FinancialGoal> goals,
  }) {
    final recs = <Recommendation>[];
    final now = DateTime.now();
    final savings = monthlyIncome - monthlyExpense;
    if (monthlyIncome > 0 && savings / monthlyIncome < 0.2) {
      recs.add(Recommendation(userId: userId, category: 'savings', title: 'Increase Savings', reason: 'Savings rate is below 20%.', recommendedAction: 'Aim to save at least 20% of income monthly.', createdAt: now));
    }
    if (monthlyExpense > 0 && currentSavings < monthlyExpense * 3) {
      recs.add(Recommendation(userId: userId, category: 'emergency', title: 'Build Emergency Fund', reason: 'Emergency fund below 3 months.', recommendedAction: 'Save 3-6 months of expenses.', createdAt: now));
    }
    if (monthlyIncome > 0 && monthlyEmi / monthlyIncome > 0.3) {
      recs.add(Recommendation(userId: userId, category: 'debt', title: 'Manage Debt', reason: 'EMI burden high.', recommendedAction: 'Consider prepaying high-interest loans.', createdAt: now));
    }
    if (investmentTotal <= 0 && monthlyIncome > 0) {
      recs.add(Recommendation(userId: userId, category: 'investment', title: 'Start Investing', reason: 'No investments recorded.', recommendedAction: 'Begin with a small SIP in a diversified fund (educational).', createdAt: now));
    }
    for (final g in goals) {
      if (g.progress < 0.5) {
        recs.add(Recommendation(userId: userId, category: 'goals', title: 'Boost Goal: ${g.name}', reason: 'Goal progress below 50%.', recommendedAction: 'Increase monthly contribution.', createdAt: now));
      }
    }
    if (recs.isEmpty) {
      recs.add(Recommendation(userId: userId, category: 'general', title: 'Stay on Track', reason: 'Finances look healthy.', recommendedAction: 'Maintain current habits and review monthly.', createdAt: now));
    }
    return recs;
  }
}
