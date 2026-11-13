import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../models/profile.dart';
import '../../providers/providers.dart';
import '../../services/insforge_service.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/ui.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _income = TextEditingController();
  String? _cityId;
  String _cityTier = 'Tier 2';
  String _language = 'en';
  List<Map<String, dynamic>> _cities = [];
  bool _loading = false;
  bool _bootstrapping = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _income.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final uid = InsforgeService.client.auth.currentUser?.id;
    try {
      final cities = await ref.read(financeRepositoryProvider).getCities();
      if (mounted) setState(() => _cities = cities);
    } catch (_) {}

    // Prefer the name captured at sign-up, then any saved profile.
    final authName = InsforgeService.client.auth.currentUser?.name;
    if (authName != null && authName.isNotEmpty) _name.text = authName;

    if (uid != null) {
      try {
        final profile = await ref.read(financeRepositoryProvider).getProfile(uid);
        if (profile != null) {
          if (profile.fullName?.isNotEmpty == true) _name.text = profile.fullName!;
          if (profile.age != null) _age.text = '${profile.age}';
          if (profile.monthlyIncome > 0) _income.text = profile.monthlyIncome.toStringAsFixed(0);
          _cityTier = profile.cityTier ?? _cityTier;
          _language = profile.preferredLanguage;
          _cityId = profile.cityId;
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _bootstrapping = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _bootstrapping
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      children: [
                        Row(children: [
                          const AppLogo(size: 34),
                          const Spacer(),
                          TextButton(
                            onPressed: () => context.go('/dashboard'),
                            child: const Text('Skip for now'),
                          ),
                        ]),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: AppGradients.header,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Icon(Icons.waving_hand_outlined, color: Colors.white, size: 26),
                            const SizedBox(height: 10),
                            Text(
                              _name.text.trim().isEmpty ? 'Let\'s set up your profile' : 'Nice to meet you, ${_name.text.trim().split(' ').first}',
                              style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                            ),
                            const SizedBox(height: 4),
                            Text('Two minutes now — sharper insights forever.',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 12.5)),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        SurfaceCard(
                          padding: const EdgeInsets.all(18),
                          child: Column(children: [
                            TextField(
                              controller: _name,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline_rounded, size: 20)),
                            ),
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(
                                child: TextField(
                                  controller: _age,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.cake_outlined, size: 20)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _income,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Monthly income', prefixIcon: Icon(Icons.currency_rupee_rounded, size: 20)),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _cityId,
                              isExpanded: true,
                              items: _cities
                                  .map((c) => DropdownMenuItem(
                                        value: c['id'] as String,
                                        child: Text('${c['name']} (${c['tier']})', overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                setState(() {
                                  _cityId = v;
                                  final city = _cities.firstWhere((c) => c['id'] == v, orElse: () => const {});
                                  if (city['tier'] != null) _cityTier = city['tier'] as String;
                                });
                              },
                              decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city_outlined, size: 20)),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _cityTier,
                              items: ['Tier 1', 'Tier 2', 'Tier 3'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                              onChanged: (v) => setState(() => _cityTier = v ?? _cityTier),
                              decoration: const InputDecoration(labelText: 'City tier', prefixIcon: Icon(Icons.layers_outlined, size: 20)),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _language,
                              items: const [
                                DropdownMenuItem(value: 'en', child: Text('English')),
                                DropdownMenuItem(value: 'hi', child: Text('हिन्दी (Hindi)')),
                              ],
                              onChanged: (v) => setState(() => _language = v ?? _language),
                              decoration: const InputDecoration(labelText: 'Language', prefixIcon: Icon(Icons.translate_rounded, size: 20)),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: GradientButton(
                            label: 'Complete setup',
                            icon: Icons.check_circle_outline_rounded,
                            loading: _loading,
                            onPressed: _loading ? null : _save,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text('You can edit all of this later from Profile.',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _save() async {
    final uid = InsforgeService.client.auth.currentUser?.id;
    if (uid == null) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add your name to continue.')));
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = ref.read(financeRepositoryProvider);
      final existing = await repo.getProfile(uid);
      final profile = existing ?? Profile(userId: uid);
      profile.fullName = name;
      profile.age = int.tryParse(_age.text.trim());
      profile.monthlyIncome = double.tryParse(_income.text.trim()) ?? 0;
      profile.cityId = _cityId;
      profile.cityTier = _cityTier;
      profile.preferredLanguage = _language;
      profile.onboardingCompleted = true;
      await repo.upsertProfile(profile);
      await repo.upsertSettings(UserSettings(userId: uid, simpleLanguageMode: false, voiceEnabled: false));
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
