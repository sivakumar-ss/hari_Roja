class RiskEngine {
  static Map<String, dynamic> compute({
    required double monthlyIncome,
    required double monthlyExpense,
    required double currentSavings,
    required double totalDebt,
    required double monthlyEmi,
    required double investmentTotal,
  }) {
    final factors = <String>[];
    double score = 0;
    // EMI burden
    final emiRatio = monthlyIncome > 0 ? monthlyEmi / monthlyIncome : 0.0;
    if (emiRatio > 0.5) { factors.add('EMI burden exceeds 50% of income'); score += 3; }
    else if (emiRatio > 0.3) { factors.add('EMI burden between 30-50%'); score += 1.5; }
    // Savings
    final savings = monthlyIncome - monthlyExpense;
    if (savings < 0) { factors.add('Expenses exceed income'); score += 3; }
    // Emergency fund
    final months = monthlyExpense > 0 ? currentSavings / monthlyExpense : 0.0;
    if (months < 3) { factors.add('Emergency fund below 3 months'); score += 2; }
    // Debt
    if (totalDebt > monthlyIncome * 12) { factors.add('Debt exceeds annual income'); score += 2; }
    // Investments
    if (investmentTotal <= 0) { factors.add('No investments'); score += 1; }

    String level;
    if (score >= 5) level = 'HIGH';
    else if (score >= 2) level = 'MEDIUM';
    else level = 'LOW';
    if (factors.isEmpty) factors.add('Healthy financial position');
    return {'level': level, 'factors': factors};
  }
}
