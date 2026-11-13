class Profile {
  final String userId;
  String? fullName;
  int? age;
  String? education;
  String? occupation;
  double monthlyIncome;
  String? cityId;
  String? cityTier;
  String preferredLanguage;
  bool simpleLanguageMode;
  bool voiceEnabled;
  bool onboardingCompleted;

  Profile({
    required this.userId,
    this.fullName,
    this.age,
    this.education,
    this.occupation,
    this.monthlyIncome = 0,
    this.cityId,
    this.cityTier,
    this.preferredLanguage = 'en',
    this.simpleLanguageMode = false,
    this.voiceEnabled = false,
    this.onboardingCompleted = false,
  });

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        userId: j['user_id'] as String,
        fullName: j['full_name'] as String?,
        age: j['age'] as int?,
        education: j['education'] as String?,
        occupation: j['occupation'] as String?,
        monthlyIncome: (j['monthly_income'] as num?)?.toDouble() ?? 0,
        cityId: j['city_id'] as String?,
        cityTier: j['city_tier'] as String?,
        preferredLanguage: (j['preferred_language'] as String?) ?? 'en',
        simpleLanguageMode: (j['simple_language_mode'] as bool?) ?? false,
        voiceEnabled: (j['voice_enabled'] as bool?) ?? false,
        onboardingCompleted: (j['onboarding_completed'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'full_name': fullName,
        'age': age,
        'education': education,
        'occupation': occupation,
        'monthly_income': monthlyIncome,
        'city_id': cityId,
        'city_tier': cityTier,
        'preferred_language': preferredLanguage,
        'simple_language_mode': simpleLanguageMode,
        'voice_enabled': voiceEnabled,
        'onboarding_completed': onboardingCompleted,
      };
}
