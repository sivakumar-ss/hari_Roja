import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/ui.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
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
        child: Stack(
          children: [
            const _AuthBackdropArt(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppLogo(size: 62, light: true),
                        const SizedBox(height: 26),
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Welcome back',
                                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.6)),
                              const SizedBox(height: 6),
                              const Text('Sign in to keep growing your money.',
                                  style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
                              const SizedBox(height: 22),
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
                                onSubmitted: (_) => _login(),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  labelText: 'Password',
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
                                  label: 'Sign in',
                                  icon: Icons.arrow_forward_rounded,
                                  loading: _loading,
                                  onPressed: _loading ? null : _login,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("New here?", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                  TextButton(
                                    onPressed: () => context.push('/register'),
                                    child: const Text('Create an account', style: TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text('Secure sync with InsForge • Your data stays yours',
                            style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    final email = _email.text.trim();
    if (email.isEmpty || _pass.text.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signIn(email, _pass.text);
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendly(Object e) {
    final raw = e.toString();
    if (raw.toLowerCase().contains('invalid credentials')) return 'That email and password do not match.';
    if (raw.contains('401')) return 'Incorrect email or password.';
    if (raw.toLowerCase().contains('network') || raw.toLowerCase().contains('socket')) {
      return 'Cannot reach the server. Check your connection.';
    }
    return raw.replaceFirst('Exception: ', '');
  }
}

class _AuthBackdropArt extends StatelessWidget {
  const _AuthBackdropArt();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _blob(260, Colors.white.withValues(alpha: 0.10)),
          ),
          Positioned(
            bottom: -110,
            left: -80,
            child: _blob(300, const Color(0xFFF59E0B).withValues(alpha: 0.14)),
          ),
          Positioned(
            top: 140,
            left: -60,
            child: _blob(170, Colors.white.withValues(alpha: 0.06)),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
