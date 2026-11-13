import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/insforge_service.dart';
import '../widgets/scaffold_with_nav.dart';

import '../features/splash/splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/income/income_screen.dart';
import '../features/expenses/expense_screen.dart';
import '../features/savings/savings_screen.dart';
import '../features/loans/loans_screen.dart';
import '../features/investments/investments_screen.dart';
import '../features/goals/goals_screen.dart';
import '../features/alerts/alerts_screen.dart';
import '../features/predictions/predictions_screen.dart';
import '../features/recommendations/recommendations_screen.dart';
import '../features/chatbot/chatbot_screen.dart';
import '../features/government_schemes/schemes_screen.dart';
import '../features/risk/risk_screen.dart';
import '../features/inflation/inflation_screen.dart';
import '../features/analytics/patterns_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/health_score/health_score_screen.dart';
import '../features/voice/voice_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final path = state.matchedLocation;
      // The splash decides where to go once it has finished animating.
      if (path == '/splash') return null;
      final loggingIn = path == '/login' || path == '/register';
      final uid = InsforgeService.client.auth.currentUser?.id;
      if (uid == null && !loggingIn && path != '/onboarding') return '/login';
      if (uid != null && loggingIn) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/income', builder: (_, __) => const IncomeScreen()),
          GoRoute(path: '/goals', builder: (_, __) => const GoalsScreen()),
          GoRoute(path: '/chatbot', builder: (_, __) => const ChatbotScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),
      // Other screens without bottom nav
      GoRoute(path: '/expenses', builder: (_, __) => const ExpenseScreen()),
      GoRoute(path: '/savings', builder: (_, __) => const SavingsScreen()),
      GoRoute(path: '/loans', builder: (_, __) => const LoansScreen()),
      GoRoute(path: '/investments', builder: (_, __) => const InvestmentsScreen()),
      GoRoute(path: '/alerts', builder: (_, __) => const AlertsScreen()),
      GoRoute(path: '/predictions', builder: (_, __) => const PredictionsScreen()),
      GoRoute(path: '/recommendations', builder: (_, __) => const RecommendationsScreen()),
      GoRoute(path: '/schemes', builder: (_, __) => const SchemesScreen()),
      GoRoute(path: '/risk', builder: (_, __) => const RiskScreen()),
      GoRoute(path: '/inflation', builder: (_, __) => const InflationScreen()),
      GoRoute(path: '/patterns', builder: (_, __) => const PatternsScreen()),
      GoRoute(path: '/health', builder: (_, __) => const HealthScoreScreen()),
      GoRoute(path: '/voice', builder: (_, __) => const VoiceScreen()),
    ],
  );
});
