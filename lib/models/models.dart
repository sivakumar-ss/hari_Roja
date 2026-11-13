class IncomeEntry {
  final String? id;
  final String userId;
  final double amount;
  final String category;
  final String? source;
  final DateTime entryDate;
  final String? description;
  IncomeEntry({this.id, required this.userId, required this.amount, required this.category, this.source, required this.entryDate, this.description});
  factory IncomeEntry.fromJson(Map<String,dynamic> j) => IncomeEntry(
    id: j['id'] as String?,
    userId: j['user_id'] as String,
    amount: (j['amount'] as num).toDouble(),
    category: j['category'] as String,
    source: j['source'] as String?,
    entryDate: DateTime.parse(j['entry_date'] as String),
    description: j['description'] as String?,
  );
  Map<String,dynamic> toJson() => {'user_id':userId,'amount':amount,'category':category,'source':source,'entry_date':entryDate.toIso8601String().split('T').first,'description':description};
}

class ExpenseEntry {
  final String? id;
  final String userId;
  final double amount;
  final String category;
  final DateTime entryDate;
  final String? description;
  ExpenseEntry({this.id, required this.userId, required this.amount, required this.category, required this.entryDate, this.description});
  factory ExpenseEntry.fromJson(Map<String,dynamic> j) => ExpenseEntry(
    id: j['id'] as String?,
    userId: j['user_id'] as String,
    amount: (j['amount'] as num).toDouble(),
    category: j['category'] as String,
    entryDate: DateTime.parse(j['entry_date'] as String),
    description: j['description'] as String?,
  );
  Map<String,dynamic> toJson() => {'user_id':userId,'amount':amount,'category':category,'entry_date':entryDate.toIso8601String().split('T').first,'description':description};
}

class SavingsEntry {
  final String? id;
  final String userId;
  final double amount;
  final DateTime entryDate;
  final String? description;
  SavingsEntry({this.id, required this.userId, required this.amount, required this.entryDate, this.description});
  factory SavingsEntry.fromJson(Map<String,dynamic> j) => SavingsEntry(
    id: j['id'] as String?,
    userId: j['user_id'] as String,
    amount: (j['amount'] as num).toDouble(),
    entryDate: DateTime.parse(j['entry_date'] as String),
    description: j['description'] as String?,
  );
  Map<String,dynamic> toJson() => {'user_id':userId,'amount':amount,'entry_date':entryDate.toIso8601String().split('T').first,'description':description};
}

class Loan {
  final String? id;
  final String userId;
  final String name;
  final double principal;
  final double outstanding;
  final double interestRate;
  final int tenureMonths;
  final double emi;
  final DateTime? startDate;
  final DateTime? dueDate;
  Loan({this.id, required this.userId, required this.name, required this.principal, required this.outstanding, required this.interestRate, required this.tenureMonths, required this.emi, this.startDate, this.dueDate});
  factory Loan.fromJson(Map<String,dynamic> j) => Loan(
    id: j['id'] as String?,
    userId: j['user_id'] as String,
    name: j['name'] as String,
    principal: (j['principal'] as num).toDouble(),
    outstanding: (j['outstanding'] as num).toDouble(),
    interestRate: (j['interest_rate'] as num).toDouble(),
    tenureMonths: j['tenure_months'] as int,
    emi: (j['emi'] as num).toDouble(),
    startDate: j['start_date']==null?null:DateTime.parse(j['start_date'] as String),
    dueDate: j['due_date']==null?null:DateTime.parse(j['due_date'] as String),
  );
  Map<String,dynamic> toJson() => {'user_id':userId,'name':name,'principal':principal,'outstanding':outstanding,'interest_rate':interestRate,'tenure_months':tenureMonths,'emi':emi,'start_date':startDate?.toIso8601String().split('T').first,'due_date':dueDate?.toIso8601String().split('T').first};
}

class Investment {
  final String? id;
  final String userId;
  final String type;
  final String? name;
  final double amount;
  final DateTime investedOn;
  final String? notes;
  Investment({this.id, required this.userId, required this.type, this.name, required this.amount, required this.investedOn, this.notes});
  factory Investment.fromJson(Map<String,dynamic> j) => Investment(
    id: j['id'] as String?,
    userId: j['user_id'] as String,
    type: j['type'] as String,
    name: j['name'] as String?,
    amount: (j['amount'] as num).toDouble(),
    investedOn: DateTime.parse(j['invested_on'] as String),
    notes: j['notes'] as String?,
  );
  Map<String,dynamic> toJson() => {'user_id':userId,'type':type,'name':name,'amount':amount,'invested_on':investedOn.toIso8601String().split('T').first,'notes':notes};
}

class FinancialGoal {
  final String? id;
  final String userId;
  final String name;
  final String goalType;
  final double targetAmount;
  double currentAmount;
  final DateTime? targetDate;
  final double monthlyContribution;
  final double inflationRate;
  String status;
  FinancialGoal({this.id, required this.userId, required this.name, required this.goalType, required this.targetAmount, this.currentAmount=0, this.targetDate, this.monthlyContribution=0, this.inflationRate=0.06, this.status='active'});
  double get progress => targetAmount<=0?0:(currentAmount/targetAmount).clamp(0,1);
  factory FinancialGoal.fromJson(Map<String,dynamic> j) => FinancialGoal(
    id: j['id'] as String?,
    userId: j['user_id'] as String,
    name: j['name'] as String,
    goalType: j['goal_type'] as String,
    targetAmount: (j['target_amount'] as num).toDouble(),
    currentAmount: (j['current_amount'] as num?)?.toDouble() ?? 0,
    targetDate: j['target_date']==null?null:DateTime.parse(j['target_date'] as String),
    monthlyContribution: (j['monthly_contribution'] as num?)?.toDouble() ?? 0,
    inflationRate: (j['inflation_rate'] as num?)?.toDouble() ?? 0.06,
    status: (j['status'] as String?) ?? 'active',
  );
  Map<String,dynamic> toJson() => {'user_id':userId,'name':name,'goal_type':goalType,'target_amount':targetAmount,'current_amount':currentAmount,'target_date':targetDate?.toIso8601String().split('T').first,'monthly_contribution':monthlyContribution,'inflation_rate':inflationRate,'status':status};
}

class FinancialScore {
  final String? id;
  final String userId;
  final double overallScore;
  final double savingsScore;
  final double spendingScore;
  final double debtScore;
  final double emergencyScore;
  final double investmentScore;
  final double retirementScore;
  final DateTime computedAt;
  FinancialScore({this.id, required this.userId, required this.overallScore, required this.savingsScore, required this.spendingScore, required this.debtScore, required this.emergencyScore, required this.investmentScore, required this.retirementScore, required this.computedAt});
  factory FinancialScore.fromJson(Map<String,dynamic> j) => FinancialScore(
    id: j['id'] as String?,
    userId: j['user_id'] as String,
    overallScore: (j['overall_score'] as num).toDouble(),
    savingsScore: (j['savings_score'] as num).toDouble(),
    spendingScore: (j['spending_score'] as num).toDouble(),
    debtScore: (j['debt_score'] as num).toDouble(),
    emergencyScore: (j['emergency_score'] as num).toDouble(),
    investmentScore: (j['investment_score'] as num).toDouble(),
    retirementScore: (j['retirement_score'] as num).toDouble(),
    computedAt: DateTime.parse(j['computed_at'] as String),
  );
}

class FinancialRisk {
  final String? id;
  final String userId;
  final String riskLevel;
  final List<String> factors;
  final DateTime computedAt;
  FinancialRisk({this.id, required this.userId, required this.riskLevel, required this.factors, required this.computedAt});
  factory FinancialRisk.fromJson(Map<String,dynamic> j) => FinancialRisk(
    id: j['id'] as String?,
    userId: j['user_id'] as String,
    riskLevel: j['risk_level'] as String,
    factors: (j['factors'] as List?)?.map((e)=>e.toString()).toList() ?? [],
    computedAt: DateTime.parse(j['computed_at'] as String),
  );
}

class Prediction {
  final String? id;
  final String userId;
  final String modelType;
  final String modelVersion;
  final String target;
  final int horizonMonths;
  final List<double> values;
  final String confidence;
  final double? validationMetric;
  final DateTime? trainedAt;
  final DateTime createdAt;
  Prediction({this.id, required this.userId, required this.modelType, required this.modelVersion, required this.target, required this.horizonMonths, required this.values, required this.confidence, this.validationMetric, this.trainedAt, required this.createdAt});
  factory Prediction.fromJson(Map<String,dynamic> j) => Prediction(
    id: j['id'] as String?,
    userId: j['user_id'] as String,
    modelType: j['model_type'] as String,
    modelVersion: j['model_version'] as String,
    target: j['target'] as String,
    horizonMonths: j['horizon_months'] as int,
    values: (j['values'] as List).map((e)=>(e as num).toDouble()).toList(),
    confidence: j['confidence'] as String,
    validationMetric: (j['validation_metric'] as num?)?.toDouble(),
    trainedAt: j['trained_at']==null?null:DateTime.parse(j['trained_at'] as String),
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

class Recommendation {
  final String? id;
  final String userId;
  final String category;
  final String title;
  final String reason;
  final Map<String,dynamic>? supportingData;
  final String recommendedAction;
  final String? expectedImpact;
  String status;
  final DateTime createdAt;
  Recommendation({this.id, required this.userId, required this.category, required this.title, required this.reason, this.supportingData, required this.recommendedAction, this.expectedImpact, this.status='active', required this.createdAt});
  factory Recommendation.fromJson(Map<String,dynamic> j) => Recommendation(
    id: j['id'] as String?,
    userId: j['user_id'] as String,
    category: j['category'] as String,
    title: j['title'] as String,
    reason: j['reason'] as String,
    supportingData: j['supporting_data'] as Map<String,dynamic>?,
    recommendedAction: j['recommended_action'] as String,
    expectedImpact: j['expected_impact'] as String?,
    status: (j['status'] as String?) ?? 'active',
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

class Alert {
  final String? id;
  final String userId;
  final String alertType;
  final String title;
  final String message;
  final String severity;
  final Map<String,dynamic>? triggeringData;
  bool isRead;
  bool isDismissed;
  final DateTime createdAt;
  Alert({this.id, required this.userId, required this.alertType, required this.title, required this.message, required this.severity, this.triggeringData, this.isRead=false, this.isDismissed=false, required this.createdAt});
  factory Alert.fromJson(Map<String,dynamic> j) => Alert(
    id: j['id'] as String?,
    userId: j['user_id'] as String,
    alertType: j['alert_type'] as String,
    title: j['title'] as String,
    message: j['message'] as String,
    severity: j['severity'] as String,
    triggeringData: j['triggering_data'] as Map<String,dynamic>?,
    isRead: (j['is_read'] as bool?) ?? false,
    isDismissed: (j['is_dismissed'] as bool?) ?? false,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

class GovernmentScheme {
  final String? id;
  final String code;
  final String name;
  final String description;
  final String eligibility;
  final String? conditions;
  final String officialUrl;
  final DateTime lastReviewed;
  GovernmentScheme({this.id, required this.code, required this.name, required this.description, required this.eligibility, this.conditions, required this.officialUrl, required this.lastReviewed});
  factory GovernmentScheme.fromJson(Map<String,dynamic> j) => GovernmentScheme(
    id: j['id'] as String?,
    code: j['code'] as String,
    name: j['name'] as String,
    description: j['description'] as String,
    eligibility: j['eligibility'] as String,
    conditions: j['conditions'] as String?,
    officialUrl: j['official_url'] as String,
    lastReviewed: DateTime.parse(j['last_reviewed'] as String),
  );
}

class ChatSession {
  final String? id;
  final String userId;
  String? title;
  final DateTime createdAt;
  DateTime updatedAt;
  ChatSession({this.id, required this.userId, this.title, required this.createdAt, required this.updatedAt});
  factory ChatSession.fromJson(Map<String,dynamic> j) => ChatSession(
    id: j['id'] as String?,
    userId: j['user_id'] as String,
    title: j['title'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
    updatedAt: DateTime.parse(j['updated_at'] as String),
  );
}

class ChatMessage {
  final String? id;
  final String sessionId;
  final String userId;
  final String role;
  final String content;
  final DateTime createdAt;
  ChatMessage({this.id, required this.sessionId, required this.userId, required this.role, required this.content, required this.createdAt});
  factory ChatMessage.fromJson(Map<String,dynamic> j) => ChatMessage(
    id: j['id'] as String?,
    sessionId: j['session_id'] as String,
    userId: j['user_id'] as String,
    role: j['role'] as String,
    content: j['content'] as String,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

class UserSettings {
  final String userId;
  String theme;
  bool notificationsEnabled;
  bool simpleLanguageMode;
  bool voiceEnabled;
  UserSettings({required this.userId, this.theme='system', this.notificationsEnabled=true, this.simpleLanguageMode=false, this.voiceEnabled=false});
  factory UserSettings.fromJson(Map<String,dynamic> j) => UserSettings(
    userId: j['user_id'] as String,
    theme: (j['theme'] as String?) ?? 'system',
    notificationsEnabled: (j['notifications_enabled'] as bool?) ?? true,
    simpleLanguageMode: (j['simple_language_mode'] as bool?) ?? false,
    voiceEnabled: (j['voice_enabled'] as bool?) ?? false,
  );
  Map<String,dynamic> toJson() => {'user_id':userId,'theme':theme,'notifications_enabled':notificationsEnabled,'simple_language_mode':simpleLanguageMode,'voice_enabled':voiceEnabled};
}
