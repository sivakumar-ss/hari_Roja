import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/profile.dart';
import '../../providers/providers.dart';
import '../../services/insforge_service.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/ui.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1B4B),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.authBackdrop),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -70,
                left: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => context.pop(),
                              style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.12), foregroundColor: Colors.white),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            const Spacer(),
                            const AppLogo(size: 34, light: true),
                          ],
                        ),
                        const SizedBox(height: 20),
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Create your account',
                                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.6)),
                              const SizedBox(height: 6),
                              const Text('Your name personalises the whole app.',
                                  style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
                              const SizedBox(height: 22),
                              TextField(
                                controller: _name,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                decoration: const InputDecoration(
                                  labelText: 'Full name',
                                  hintText: 'e.g. Ananya Sharma',
                                  prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'you@example.com',
                                  prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _pass,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _register(),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: 'At least 6 characters',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                                  ),
                                ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                  decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(14)),
                                  child: Row(children: [
                                    const Icon(Icons.error_outline_rounded, size: 17, color: AppColors.danger),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(_error!,
                                          style: const TextStyle(fontSize: 12.5, color: AppColors.danger, fontWeight: FontWeight.w600)),
                                    ),
                                  ]),
                                ),
                              ],
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: GradientButton(
                                  label: 'Create account',
                                  icon: Icons.rocket_launch_outlined,
                                  loading: _loading,
                                  onPressed: _loading ? null : _register,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text('By continuing you agree to keep your own financial data accurate.',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _pass.text;

    if (name.isEmpty) {
      setState(() => _error = 'Please enter your name — it is used across the app.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signUp(email, password, name: name);

      // Store the name the user typed so the dashboard/profile greet them
      // immediately, even before onboarding runs.
      final uid = InsforgeService.client.auth.currentUser?.id;
      if (uid != null) {
        try {
          final repo = ref.read(financeRepositoryProvider);
          final existing = await repo.getProfile(uid);
          final profile = existing ?? Profile(userId: uid);
          profile.fullName = name;
          await repo.upsertProfile(profile);
        } catch (_) {
          // Non-fatal: onboarding will upsert the profile again.
        }
      }
      if (mounted) context.go('/onboarding');
    } catch (e) {
      if (mounted) setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendly(Object e) {
    final raw = e.toString().replaceFirst('Exception: ', '');
    final lower = raw.toLowerCase();
    if (lower.contains('already') || lower.contains('exists') || lower.contains('duplicate')) {
      return 'An account with this email already exists. Try signing in.';
    }
    if (lower.contains('network') || lower.contains('socket')) {
      return 'Cannot reach the server. Check your connection.';
    }
    return raw;
  }
}
