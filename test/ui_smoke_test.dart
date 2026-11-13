import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_advisor/core/theme/app_theme.dart';
import 'package:finance_advisor/features/auth/login_screen.dart';
import 'package:finance_advisor/features/splash/splash_screen.dart';
import 'package:finance_advisor/widgets/ui.dart';

void main() {
  testWidgets('login screen renders the redesigned form', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const LoginScreen(),
        ),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty state and gradient button render without errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Column(
            children: [
              const EmptyState(icon: Icons.savings_outlined, title: 'No income yet', message: 'Add your salary.'),
              GradientButton(label: 'Continue', onPressed: () {}),
            ],
          ),
        ),
      ),
    );

    expect(find.text('No income yet'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('splash shows the brand then routes to login when signed out', (tester) async {
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, __) => const Scaffold(body: Text('Login route'))),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(theme: AppTheme.light(), routerConfig: router));

    expect(find.text('Finance Advisor'), findsOneWidget);
    expect(find.text('Your money, understood.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();

    expect(find.text('Login route'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('initials avatar derives initials from the full name', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: InitialsAvatar(name: 'Ananya Sharma'))),
      ),
    );

    expect(find.text('AS'), findsOneWidget);
  });
}
