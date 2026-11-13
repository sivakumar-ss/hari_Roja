import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../services/insforge_service.dart';
import '../../widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<double> _scale = Tween<double>(begin: 0.82, end: 1).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
  );
  late final Animation<Offset> _slide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
  );

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1350), _continue);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    if (!mounted) return;
    String? uid;
    try {
      uid = InsforgeService.client.auth.currentUser?.id;
    } catch (_) {
      uid = null;
    }
    context.go(uid == null ? '/login' : '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1B4B),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.authBackdrop),
        child: Stack(
          children: [
            Positioned(top: -100, right: -70, child: _blob(280, Colors.white.withValues(alpha: 0.08))),
            Positioned(bottom: -120, left: -90, child: _blob(320, AppColors.accent.withValues(alpha: 0.12))),
            Positioned(top: 180, left: -50, child: _blob(160, Colors.white.withValues(alpha: 0.05))),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: const AppLogo(size: 92, showText: false, light: true),
                    ),
                  ),
                  const SizedBox(height: 26),
                  SlideTransition(
                    position: _slide,
                    child: FadeTransition(
                      opacity: _fade,
                      child: Column(
                        children: [
                          const Text(
                            'Finance Advisor',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your money, understood.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 52,
              child: FadeTransition(
                opacity: _fade,
                child: Column(
                  children: [
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.85)),
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Securing your data',
                      style: TextStyle(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.6), letterSpacing: 0.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}
