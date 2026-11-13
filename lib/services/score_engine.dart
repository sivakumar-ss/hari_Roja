

class ScoreEngine {
  /// Returns a FinancialScore-like map and component scores.
  static Map<String, double> compute({
    required double monthlyIncome,
    required double monthlyExpense,
    required double currentSavings,
    required double totalDebtOutstanding,
    required double monthlyEmi,
    required double investmentTotal,
    required int age,
    required double emergencyFundTarget,
  }) {
    // Savings rate
    final savings = monthlyIncome - monthlyExpense;
    final savingsRate = monthlyIncome > 0 ? (savings / monthlyIncome).clamp(-1.0, 1.0) : 0.0;

    // Component scores 0-100
    double savingsScore = (savingsRate * 100).clamp(0, 100);
    if (savingsRate < 0) savingsScore = 0;

    // Spending score: lower expense ratio better
    final expenseRatio = monthlyIncome > 0 ? (monthlyExpense / monthlyIncome) : 1.0;
    double spendingScore = ((1 - expenseRatio) * 100).clamp(0, 100);
    if (spendingScore < 0) spendingScore = 0;

    // Debt score: EMI burden. <30% income good
    final emiRatio = monthlyIncome > 0 ? (monthlyEmi / monthlyIncome) : 0.0;
    double debtScore = (100 - (emiRatio * 200)).clamp(0, 100);
    if (totalDebtOutstanding == 0) debtScore = 100;

    // Emergency fund: months of expenses covered
    final monthsCovered = monthlyExpense > 0 ? (currentSavings / monthlyExpense) : 0.0;
    double emergencyScore = (monthsCovered / 6 * 100).clamp(0, 100);

    // Investment score: presence + ratio
    final investRatio = monthlyIncome > 0 ? (investmentTotal / (monthlyIncome * 12)) : 0.0;
    double investmentScore = (investRatio * 100).clamp(0, 100);
    if (investmentTotal <= 0) investmentScore = 20;

    // Retirement readiness: age-based heuristic
    double retirementScore = 50;
    if (age >= 40) {
      retirementScore = investmentTotal > 0 ? 60 : 30;
    } else {
      retirementScore = investmentTotal > 0 ? 55 : 40;
    }
    retirementScore = retirementScore.clamp(0, 100);

    final overall = (savingsScore * 0.2 + spendingScore * 0.2 + debtScore * 0.2 +
            emergencyScore * 0.15 + investmentScore * 0.15 + retirementScore * 0.1)
        .clamp(0, 100);

    return {
      'overall': overall.toDouble(),
      'savings': savingsScore.toDouble(),
      'spending': spendingScore.toDouble(),
      'debt': debtScore.toDouble(),
      'emergency': emergencyScore.toDouble(),
      'investment': investmentScore.toDouble(),
      'retirement': retirementScore.toDouble(),
      'savingsRate': (savingsRate * 100).toDouble(),
      'monthsCovered': monthsCovered.toDouble(),
      'emiRatio': (emiRatio * 100).toDouble(),
    };
  }

  static String reasons(Map<String,double> c) {
    final parts = <String>[];
    if (c['savingsRate']! >= 20) parts.add('Good savings rate');
    else parts.add('Low savings rate');
    if (c['monthsCovered']! >= 6) parts.add('Strong emergency fund');
    else parts.add('Emergency fund needs improvement');
    if (c['emiRatio']! > 40) parts.add('High EMI burden');
    return parts.join('; ');
  }
}
