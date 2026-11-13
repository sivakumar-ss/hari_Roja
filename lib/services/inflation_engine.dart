class InflationEngine {
  static Map<String, double> project({
    required double currentCost,
    required double annualInflation,
    required int years,
    required double monthlyContribution,
  }) {
    final futureCost = currentCost * (1 + annualInflation).powInt(years);
    // required monthly contribution to reach futureCost
    final months = years * 12;
    final r = annualInflation / 12;
    double requiredMonthly;
    if (r == 0) {
      requiredMonthly = futureCost / months;
    } else {
      requiredMonthly = futureCost * r / ((1 + r).powInt(months) - 1);
    }
    return {
      'currentCost': currentCost,
      'futureCost': futureCost,
      'requiredMonthly': requiredMonthly,
    };
  }
}

extension _Pow on double {
  double powInt(int n) {
    double r = 1;
    for (int i = 0; i < n; i++) r *= this;
    return r;
  }
}
