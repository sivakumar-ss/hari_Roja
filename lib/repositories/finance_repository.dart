import '../models/models.dart';
import '../models/profile.dart';
import '../services/insforge_service.dart';

class FinanceRepository {
  final _db = InsforgeService.client.database;

  // --- Profile ---
  Future<Profile?> getProfile(String userId) async {
    final rows = await _db.from('profiles').select().eq('user_id', userId).execute();
    if (rows.isEmpty) return null;
    return Profile.fromJson(Map<String,dynamic>.from(rows.first));
  }
  Future<void> upsertProfile(Profile p) async {
    await _db.from('profiles').upsert([p.toJson()], onConflict: 'user_id').execute();
  }

  // --- Cities ---
  Future<List<Map<String,dynamic>>> getCities() async {
    final rows = await _db.from('cities').select().execute();
    return List<Map<String,dynamic>>.from(rows);
  }

  // --- Income ---
  Future<List<IncomeEntry>> listIncome(String userId) async {
    final rows = await _db.from('income_entries').select().eq('user_id', userId).order('entry_date', ascending: false).execute();
    return List<IncomeEntry>.from(rows.map(IncomeEntry.fromJson));
  }
  Future<void> addIncome(IncomeEntry e) async {
    await _db.from('income_entries').insert([e.toJson()]).execute();
  }
  Future<void> updateIncome(IncomeEntry e) async {
    await _db.from('income_entries').update(e.toJson()).eq('id', e.id!).execute();
  }
  Future<void> deleteIncome(String id) async {
    await _db.from('income_entries').delete().eq('id', id).execute();
  }

  // --- Expense ---
  Future<List<ExpenseEntry>> listExpenses(String userId) async {
    final rows = await _db.from('expense_entries').select().eq('user_id', userId).order('entry_date', ascending: false).execute();
    return List<ExpenseEntry>.from(rows.map(ExpenseEntry.fromJson));
  }
  Future<void> addExpense(ExpenseEntry e) async {
    await _db.from('expense_entries').insert([e.toJson()]).execute();
  }
  Future<void> updateExpense(ExpenseEntry e) async {
    await _db.from('expense_entries').update(e.toJson()).eq('id', e.id!).execute();
  }
  Future<void> deleteExpense(String id) async {
    await _db.from('expense_entries').delete().eq('id', id).execute();
  }

  // --- Savings ---
  Future<List<SavingsEntry>> listSavings(String userId) async {
    final rows = await _db.from('savings_entries').select().eq('user_id', userId).order('entry_date', ascending: false).execute();
    return List<SavingsEntry>.from(rows.map(SavingsEntry.fromJson));
  }
  Future<void> addSavings(SavingsEntry e) async {
    await _db.from('savings_entries').insert([e.toJson()]).execute();
  }

  // --- Loans ---
  Future<List<Loan>> listLoans(String userId) async {
    final rows = await _db.from('loans').select().eq('user_id', userId).execute();
    return List<Loan>.from(rows.map(Loan.fromJson));
  }
  Future<void> addLoan(Loan l) async {
    await _db.from('loans').insert([l.toJson()]).execute();
  }
  Future<void> updateLoan(Loan l) async {
    await _db.from('loans').update(l.toJson()).eq('id', l.id!).execute();
  }
  Future<void> deleteLoan(String id) async {
    await _db.from('loans').delete().eq('id', id).execute();
  }

  // --- Investments ---
  Future<List<Investment>> listInvestments(String userId) async {
    final rows = await _db.from('investments').select().eq('user_id', userId).execute();
    return List<Investment>.from(rows.map(Investment.fromJson));
  }
  Future<void> addInvestment(Investment i) async {
    await _db.from('investments').insert([i.toJson()]).execute();
  }
  Future<void> deleteInvestment(String id) async {
    await _db.from('investments').delete().eq('id', id).execute();
  }

  // --- Goals ---
  Future<List<FinancialGoal>> listGoals(String userId) async {
    final rows = await _db.from('financial_goals').select().eq('user_id', userId).execute();
    return List<FinancialGoal>.from(rows.map(FinancialGoal.fromJson));
  }
  Future<void> addGoal(FinancialGoal g) async {
    await _db.from('financial_goals').insert([g.toJson()]).execute();
  }
  Future<void> updateGoal(FinancialGoal g) async {
    await _db.from('financial_goals').update(g.toJson()).eq('id', g.id!).execute();
  }
  Future<void> deleteGoal(String id) async {
    await _db.from('financial_goals').delete().eq('id', id).execute();
  }

  // --- Scores ---
  Future<FinancialScore?> latestScore(String userId) async {
    final rows = await _db.from('financial_scores').select().eq('user_id', userId).order('computed_at', ascending: false).limit(1).execute();
    if (rows.isEmpty) return null;
    return FinancialScore.fromJson(Map<String,dynamic>.from(rows.first));
  }
  Future<void> saveScore(FinancialScore s) async {
    await _db.from('financial_scores').insert([{
      'user_id': s.userId,
      'overall_score': s.overallScore,
      'savings_score': s.savingsScore,
      'spending_score': s.spendingScore,
      'debt_score': s.debtScore,
      'emergency_score': s.emergencyScore,
      'investment_score': s.investmentScore,
      'retirement_score': s.retirementScore,
      'inputs': null,
    }]).execute();
  }

  // --- Risks ---
  Future<FinancialRisk?> latestRisk(String userId) async {
    final rows = await _db.from('financial_risks').select().eq('user_id', userId).order('computed_at', ascending: false).limit(1).execute();
    if (rows.isEmpty) return null;
    return FinancialRisk.fromJson(Map<String,dynamic>.from(rows.first));
  }
  Future<void> saveRisk(FinancialRisk r) async {
    await _db.from('financial_risks').insert([{'user_id': r.userId, 'risk_level': r.riskLevel, 'factors': r.factors}]).execute();
  }

  // --- Predictions ---
  Future<List<Prediction>> listPredictions(String userId) async {
    final rows = await _db.from('predictions').select().eq('user_id', userId).order('created_at', ascending: false).execute();
    return List<Prediction>.from(rows.map(Prediction.fromJson));
  }
  Future<void> savePrediction(Prediction p) async {
    await _db.from('predictions').insert([{
      'user_id': p.userId,
      'model_type': p.modelType,
      'model_version': p.modelVersion,
      'target': p.target,
      'horizon_months': p.horizonMonths,
      'values': p.values,
      'confidence': p.confidence,
      'validation_metric': p.validationMetric,
      'trained_at': p.trainedAt?.toIso8601String(),
    }]).execute();
  }

  // --- Recommendations ---
  Future<List<Recommendation>> listRecommendations(String userId) async {
    final rows = await _db.from('recommendations').select().eq('user_id', userId).execute();
    return List<Recommendation>.from(rows.map(Recommendation.fromJson));
  }
  Future<void> addRecommendation(Recommendation r) async {
    await _db.from('recommendations').insert([{
      'user_id': r.userId,
      'category': r.category,
      'title': r.title,
      'reason': r.reason,
      'supporting_data': r.supportingData,
      'recommended_action': r.recommendedAction,
      'expected_impact': r.expectedImpact,
      'status': r.status,
    }]).execute();
  }
  Future<void> updateRecommendationStatus(String id, String status) async {
    await _db.from('recommendations').update({'status': status}).eq('id', id).execute();
  }

  // --- Alerts ---
  Future<List<Alert>> listAlerts(String userId) async {
    final rows = await _db.from('alerts').select().eq('user_id', userId).order('created_at', ascending: false).execute();
    return List<Alert>.from(rows.map(Alert.fromJson));
  }
  Future<void> addAlert(Alert a) async {
    await _db.from('alerts').insert([{
      'user_id': a.userId,
      'alert_type': a.alertType,
      'title': a.title,
      'message': a.message,
      'severity': a.severity,
      'triggering_data': a.triggeringData,
      'is_read': a.isRead,
      'is_dismissed': a.isDismissed,
    }]).execute();
  }
  Future<void> markAlertRead(String id) async {
    await _db.from('alerts').update({'is_read': true}).eq('id', id).execute();
  }
  Future<void> dismissAlert(String id) async {
    await _db.from('alerts').update({'is_dismissed': true}).eq('id', id).execute();
  }

  // --- Alert prefs ---
  Future<Map<String,dynamic>?> getAlertPrefs(String userId) async {
    final rows = await _db.from('alert_preferences').select().eq('user_id', userId).execute();
    if (rows.isEmpty) return null;
    return rows.first;
  }
  Future<void> upsertAlertPrefs(String userId, List<String> muted) async {
    await _db.from('alert_preferences').upsert([{'user_id': userId, 'muted_categories': muted}], onConflict: 'user_id').execute();
  }

  // --- Schemes ---
  Future<List<GovernmentScheme>> listSchemes() async {
    final rows = await _db.from('government_schemes').select().execute();
    return List<GovernmentScheme>.from(rows.map(GovernmentScheme.fromJson));
  }

  // --- Chat ---
  Future<ChatSession> createSession(String userId, {String? title}) async {
    final rows = await _db.from('chat_sessions').insert([{'user_id': userId, 'title': title}]).select().execute();
    return ChatSession.fromJson(Map<String,dynamic>.from(rows.first));
  }
  Future<List<ChatSession>> listSessions(String userId) async {
    final rows = await _db.from('chat_sessions').select().eq('user_id', userId).order('updated_at', ascending: false).execute();
    return List<ChatSession>.from(rows.map(ChatSession.fromJson));
  }
  Future<List<ChatMessage>> listMessages(String sessionId) async {
    final rows = await _db.from('chat_messages').select().eq('session_id', sessionId).order('created_at', ascending: true).execute();
    return List<ChatMessage>.from(rows.map(ChatMessage.fromJson));
  }
  Future<void> addMessage(ChatMessage m) async {
    await _db.from('chat_messages').insert([{'session_id': m.sessionId, 'user_id': m.userId, 'role': m.role, 'content': m.content}]).execute();
  }

  // --- Settings ---
  Future<UserSettings?> getSettings(String userId) async {
    final rows = await _db.from('user_settings').select().eq('user_id', userId).execute();
    if (rows.isEmpty) return null;
    return UserSettings.fromJson(Map<String,dynamic>.from(rows.first));
  }
  Future<void> upsertSettings(UserSettings s) async {
    await _db.from('user_settings').upsert([s.toJson()], onConflict: 'user_id').execute();
  }

  // --- Consents ---
  Future<void> recordConsent(String userId, String type, bool granted) async {
    await _db.from('consents').insert([{'user_id': userId, 'consent_type': type, 'granted': granted}]).execute();
  }

  // --- Pattern aggregates ---
  Future<List<Map<String,dynamic>>> getPatterns(String tier) async {
    final rows = await _db.from('pattern_aggregates').select().eq('city_tier', tier).execute();
    return List<Map<String,dynamic>>.from(rows);
  }

  // --- Data export/delete ---
  Future<void> deleteAllUserData(String userId) async {
    // delete rows in user tables
    for (final t in ['income_entries','expense_entries','savings_entries','loans','investments','financial_goals','financial_scores','financial_risks','predictions','recommendations','alerts','alert_preferences','chat_messages','chat_sessions','user_settings','consents','profiles']) {
      await _db.from(t).delete().eq('user_id', userId).execute();
    }
  }
}


