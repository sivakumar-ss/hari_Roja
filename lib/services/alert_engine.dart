import '../models/models.dart';

class AlertEngine {
  static List<Alert> evaluate({
    required String userId,
    required double monthlyIncome,
    required double monthlyExpense,
    required double savings,
    required double currentSavings,
    required double monthlyEmi,
    required List<FinancialGoal> goals,
  }) {
    final alerts = <Alert>[];
    final now = DateTime.now();
    if (monthlyExpense > monthlyIncome && monthlyIncome > 0) {
      alerts.add(Alert(userId: userId, alertType: 'overspending', title: 'Overspending', message: 'Expenses exceed income this month.', severity: 'critical', createdAt: now));
    }
    if (monthlyIncome > 0 && monthlyEmi / monthlyIncome > 0.4) {
      alerts.add(Alert(userId: userId, alertType: 'high_emi', title: 'High EMI Burden', message: 'EMI exceeds 40% of income.', severity: 'warning', createdAt: now));
    }
    if (monthlyIncome > 0 && savings / monthlyIncome < 0.1) {
      alerts.add(Alert(userId: userId, alertType: 'low_savings', title: 'Low Savings', message: 'Savings rate below 10%.', severity: 'warning', createdAt: now));
    }
    // emergency fund: 3 months
    if (monthlyExpense > 0 && currentSavings < monthlyExpense * 3) {
      alerts.add(Alert(userId: userId, alertType: 'low_emergency', title: 'Low Emergency Fund', message: 'Emergency fund below 3 months of expenses.', severity: 'warning', createdAt: now));
    }
    for (final g in goals) {
      if (g.targetDate != null) {
        final monthsLeft = g.targetDate!.difference(now).inDays / 30.0;
        if (monthsLeft > 0) {
          final required = (g.targetAmount - g.currentAmount) / monthsLeft;
          if (required > g.monthlyContribution * 1.2) {
            alerts.add(Alert(userId: userId, alertType: 'goal_deviation', title: 'Goal Off Track', message: 'Goal "${g.name}" needs higher contributions.', severity: 'info', createdAt: now));
          }
        }
      }
    }
    return alerts;
  }
}
