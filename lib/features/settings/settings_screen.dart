import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';
import '../../models/models.dart';
import '../../models/profile.dart';
import '../../providers/providers.dart';
import '../../services/insforge_service.dart';
import '../../widgets/ui.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  UserSettings? _settings;
  Profile? _profile;
  FinancialScore? _score;
  FinancialRisk? _risk;
  int _goalCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = InsforgeService.client.auth.currentUser?.id;
    if (uid == null) return;
    final repo = ref.read(financeRepositoryProvider);
    try {
      final settings = await repo.getSettings(uid);
      final profile = await repo.getProfile(uid);
      final score = await repo.latestScore(uid);
      final risk = await repo.latestRisk(uid);
      final goals = await repo.listGoals(uid);
      if (!mounted) return;
      setState(() {
        _settings = settings ?? UserSettings(userId: uid);
        _profile = profile;
        _score = score;
        _risk = risk;
        _goalCount = goals.length;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _settings ??= UserSettings(userId: uid);
        _loading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final uid = InsforgeService.client.auth.currentUser?.id;
    if (uid == null || _settings == null) return;
    try {
      await ref.read(financeRepositoryProvider).upsertSettings(_settings!);
      if (mounted) _toast('Preferences saved');
    } catch (e) {
      if (mounted) _toast('Could not save: $e');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editProfile() async {
    final uid = InsforgeService.client.auth.currentUser?.id;
    if (uid == null) return;
    final base = _profile ?? Profile(userId: uid);
    final updated = await showModalBottomSheet<Profile>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditProfileSheet(profile: base),
    );
    if (updated == null) return;

    try {
      await ref.read(financeRepositoryProvider).upsertProfile(updated);
      try {
        await InsforgeService.client.auth.updateProfile({'name': updated.fullName});
      } catch (_) {
        // The app reads the name from `profiles`, this is only a nice-to-have.
      }
      if (!mounted) return;
      setState(() => _profile = updated);
      _toast('Profile updated');
    } catch (e) {
      if (mounted) _toast('Could not update profile: $e');
    }
  }

  Future<void> _export() async {
    final uid = InsforgeService.client.auth.currentUser?.id;
    if (uid == null) return;
    final repo = ref.read(financeRepositoryProvider);
    final data = {
      'profile': (await repo.getProfile(uid))?.toJson(),
      'income': (await repo.listIncome(uid)).map((e) => e.toJson()).toList(),
      'expenses': (await repo.listExpenses(uid)).map((e) => e.toJson()).toList(),
      'savings': (await repo.listSavings(uid)).map((e) => e.toJson()).toList(),
      'loans': (await repo.listLoans(uid)).map((e) => e.toJson()).toList(),
      'goals': (await repo.listGoals(uid)).map((e) => e.toJson()).toList(),
    };
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Your data'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: SelectableText(data.toString(), style: const TextStyle(fontSize: 11.5, height: 1.5)),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _delete() async {
    final uid = InsforgeService.client.auth.currentUser?.id;
    if (uid == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete all data?'),
        content: const Text('Every income, expense, goal and score will be erased. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(financeRepositoryProvider).deleteAllUserData(uid);
    await ref.read(authRepositoryProvider).signOut();
    if (mounted) context.go('/login');
  }

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = InsforgeService.client.auth.currentUser;
    final profile = _profile;
    final name = profile?.fullName?.trim().isNotEmpty == true ? profile!.fullName!.trim() : (user?.name ?? 'Your profile');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: gradientAppBar('Profile', automaticallyImplyLeading: false, actions: [
        IconButton(tooltip: 'Edit profile', onPressed: _editProfile, icon: const Icon(Icons.edit_outlined)),
      ]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 32),
        children: [
          _hero(name, user?.email, profile),
          const SizedBox(height: 14),
          _snapshot(),
          const SectionHeader('Preferences'),
          _preferences(),
          const SectionHeader('Account'),
          _account(user?.createdAt),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign out'),
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text('Finance Advisor • v1.0.0', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _hero(String name, String? email, Profile? profile) {
    return SurfaceCard(
      gradient: AppGradients.header,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              InitialsAvatar(name: name, size: 62, showBorder: true),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4)),
                    const SizedBox(height: 3),
                    Text(email ?? 'Signed in',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
                    const SizedBox(height: 10),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      _lightPill(Icons.location_city_outlined, profile?.cityTier ?? 'City not set'),
                      if (profile?.age != null) _lightPill(Icons.cake_outlined, '${profile!.age} yrs'),
                      _lightPill(Icons.translate_rounded, profile?.preferredLanguage == 'hi' ? 'हिन्दी' : 'English'),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _completeness(profile)),
              const SizedBox(width: 14),
              Container(
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
                child: IconButton(
                  onPressed: _editProfile,
                  tooltip: 'Edit profile',
                  icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lightPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: Colors.white),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
      ]),
    );
  }

  Widget _completeness(Profile? profile) {
    final checks = <bool>[
      profile?.fullName?.trim().isNotEmpty == true,
      profile?.age != null,
      profile?.occupation?.trim().isNotEmpty == true,
      (profile?.monthlyIncome ?? 0) > 0,
      profile?.cityTier != null,
    ];
    final filled = checks.where((c) => c).length;
    final pct = filled / checks.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('Profile strength', style: TextStyle(fontSize: 11.5, color: Colors.white70, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Text('${(pct * 100).round()}%', style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            backgroundColor: Colors.white.withValues(alpha: 0.22),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          pct >= 1 ? 'All set — insights are fully personalised.' : 'Add ${checks.length - filled} more detail(s) for sharper advice.',
          style: const TextStyle(fontSize: 10.5, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _snapshot() {
    final score = _score?.overallScore;
    final risk = _risk?.riskLevel;
    final riskColor = risk == 'HIGH' ? AppColors.danger : risk == 'MEDIUM' ? AppColors.warning : AppColors.success;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: _miniStat(
              label: 'Health score',
              value: score == null ? '—' : score.toStringAsFixed(0),
              icon: Icons.favorite_outline_rounded,
              color: AppColors.primary,
              onTap: () => context.push('/health'),
            ),
          ),
          _divider(),
          Expanded(
            child: _miniStat(
              label: 'Risk level',
              value: risk ?? '—',
              icon: Icons.shield_outlined,
              color: riskColor,
              onTap: () => context.push('/risk'),
            ),
          ),
          _divider(),
          Expanded(
            child: _miniStat(
              label: 'Goals',
              value: '$_goalCount',
              icon: Icons.flag_outlined,
              color: AppColors.accentDark,
              onTap: () => context.go('/goals'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 46, color: AppColors.divider);

  Widget _miniStat({required String label, required String value, required IconData icon, required Color color, VoidCallback? onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }

  Widget _preferences() {
    final s = _settings!;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            secondary: const SoftIcon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
            title: const Text('Simple language mode'),
            subtitle: const Text('Explain money terms in plain words'),
            value: s.simpleLanguageMode,
            onChanged: (v) {
              setState(() => s.simpleLanguageMode = v);
              _saveSettings();
            },
          ),
          const Divider(indent: 70),
          SwitchListTile.adaptive(
            secondary: const SoftIcon(Icons.mic_none_rounded, color: AppColors.violet),
            title: const Text('Voice guidance'),
            subtitle: const Text('Speak amounts and hear insights'),
            value: s.voiceEnabled,
            onChanged: (v) {
              setState(() => s.voiceEnabled = v);
              _saveSettings();
            },
          ),
          const Divider(indent: 70),
          SwitchListTile.adaptive(
            secondary: const SoftIcon(Icons.notifications_none_rounded, color: AppColors.accentDark),
            title: const Text('Notifications'),
            subtitle: const Text('Bill, budget and goal reminders'),
            value: s.notificationsEnabled,
            onChanged: (v) {
              setState(() => s.notificationsEnabled = v);
              _saveSettings();
            },
          ),
        ],
      ),
    );
  }

  Widget _account(DateTime? createdAt) {
    final profile = _profile;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: const SoftIcon(Icons.currency_rupee_rounded, color: AppColors.success),
            title: const Text('Monthly income'),
            subtitle: Text(profile == null ? 'Not set yet' : Money.format(profile.monthlyIncome)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            onTap: _editProfile,
          ),
          const Divider(indent: 70),
          ListTile(
            leading: const SoftIcon(Icons.work_outline_rounded, color: AppColors.primary),
            title: const Text('Occupation'),
            subtitle: Text(profile?.occupation?.isNotEmpty == true ? profile!.occupation! : 'Not set yet'),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            onTap: _editProfile,
          ),
          if (createdAt != null) ...[
            const Divider(indent: 70),
            ListTile(
              leading: const SoftIcon(Icons.event_available_outlined, color: AppColors.violet),
              title: const Text('Member since'),
              subtitle: Text(DateFormat('MMMM yyyy').format(createdAt)),
            ),
          ],
          const Divider(indent: 70),
          ListTile(
            leading: const SoftIcon(Icons.file_download_outlined, color: AppColors.textSecondary),
            title: const Text('Export my data'),
            subtitle: const Text('View everything stored for you'),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            onTap: _export,
          ),
          const Divider(indent: 70),
          ListTile(
            leading: const SoftIcon(Icons.delete_outline_rounded, color: AppColors.danger),
            title: const Text('Delete all data', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
            subtitle: const Text('Erase every record and sign out'),
            onTap: _delete,
          ),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final Profile profile;
  const _EditProfileSheet({required this.profile});
  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _occupation;
  late final TextEditingController _income;
  late String _cityTier;
  late String _language;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _name = TextEditingController(text: p.fullName ?? '');
    _age = TextEditingController(text: p.age?.toString() ?? '');
    _occupation = TextEditingController(text: p.occupation ?? '');
    _income = TextEditingController(text: p.monthlyIncome > 0 ? p.monthlyIncome.toStringAsFixed(0) : '');
    _cityTier = p.cityTier ?? 'Tier 2';
    _language = p.preferredLanguage;
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _occupation.dispose();
    _income.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name cannot be empty.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final p = widget.profile;
    p.fullName = name;
    p.age = int.tryParse(_age.text.trim());
    p.occupation = _occupation.text.trim().isEmpty ? null : _occupation.text.trim();
    p.monthlyIncome = double.tryParse(_income.text.trim().replaceAll(',', '')) ?? 0;
    p.cityTier = _cityTier;
    p.preferredLanguage = _language;
    Navigator.pop(context, p);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Edit profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.4)),
            const SizedBox(height: 4),
            const Text('This shapes your greetings, schemes and advice.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline_rounded, size: 20)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
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
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _occupation,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Occupation', prefixIcon: Icon(Icons.work_outline_rounded, size: 20)),
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
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: GradientButton(label: 'Save changes', icon: Icons.check_rounded, loading: _saving, onPressed: _savePressed),
            ),
          ],
        ),
      ),
    );
  }

  void _savePressed() {
    _submit();
  }
}
