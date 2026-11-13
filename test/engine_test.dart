import 'package:flutter_test/flutter_test.dart';
import 'package:finance_advisor/services/score_engine.dart';
import 'package:finance_advisor/services/risk_engine.dart';
import 'package:finance_advisor/services/inflation_engine.dart';
import 'package:finance_advisor/services/ml/forecast.dart';

void main() {
  test('score within range', () {
    final c = ScoreEngine.compute(monthlyIncome: 50000, monthlyExpense: 30000, currentSavings: 200000, totalDebtOutstanding: 100000, monthlyEmi: 5000, investmentTotal: 50000, age: 30, emergencyFundTarget: 180000);
    expect(c['overall']!, greaterThanOrEqualTo(0));
    expect(c['overall']!, lessThanOrEqualTo(100));
  });
  test('risk high when emi high', () {
    final r = RiskEngine.compute(monthlyIncome: 50000, monthlyExpense: 45000, currentSavings: 1000, totalDebt: 1000000, monthlyEmi: 30000, investmentTotal: 0);
    expect(r['level'], 'HIGH');
  });
  test('inflation future cost', () {
    final r = InflationEngine.project(currentCost: 100000, annualInflation: 0.06, years: 1, monthlyContribution: 0);
    expect(r['futureCost']!, greaterThan(100000));
  });
  test('cold start low confidence', () {
    final f = MlForecast.forecast([1000,2000], horizon: 3, cityTier: 'Tier 2');
    expect(f.confidence, 'LOW');
    expect(f.modelType, 'tier_average');
  });
  test('forecast returns horizon', () {
    final f = MlForecast.forecast([1000,2000,3000,4000,5000], horizon: 3, cityTier: 'Tier 2');
    expect(f.values.length, 3);
  });
}
