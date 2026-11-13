import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../services/insforge_service.dart';
import '../../models/models.dart';
import '../../models/profile.dart';
import '../../services/scheme_eligibility.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';

class SchemesScreen extends ConsumerStatefulWidget {
  const SchemesScreen({super.key});
  @override
  ConsumerState<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends ConsumerState<SchemesScreen> {
  List<GovernmentScheme> _items = [];
  Profile? _profile;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final uid = InsforgeService.client.auth.currentUser?.id;
    if (uid == null) return;
    final items = await ref.read(financeRepositoryProvider).listSchemes();
    final profile = await ref.read(financeRepositoryProvider).getProfile(uid);
    setState(() { _items = items; _profile = profile; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final elig = _profile == null ? <String,bool>{} : SchemeEligibility.evaluate(_profile!, monthlyIncome: 0);
    return Scaffold(
      appBar: gradientAppBar('Government Schemes'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const EmptyState(
                  icon: Icons.account_balance_outlined,
                  title: 'No schemes available',
                  message: 'Government schemes could not be loaded. Pull back and try again.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final s = _items[i];
                    final e = elig[s.code] ?? false;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SurfaceCard(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            const SoftIcon(Icons.account_balance_outlined, color: AppColors.primary, size: 42, radius: 13),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(s.name,
                                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          Text(s.description, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.5)),
                          const SizedBox(height: 8),
                          Text('Eligibility: ${s.eligibility}',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.45)),
                          const SizedBox(height: 10),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            InfoPill(
                              icon: e ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                              label: e ? 'Likely eligible' : 'May not apply',
                              color: e ? AppColors.success : AppColors.textSecondary,
                            ),
                            InfoPill(icon: Icons.open_in_new_rounded, label: 'Official site', color: AppColors.primary),
                          ]),
                        ]),
                      ),
                    );
                  },
                ),
    );
  }
}
