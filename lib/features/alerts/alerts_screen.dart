import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/insforge_service.dart';
import '../../widgets/ui.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});
  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  List<Alert> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = InsforgeService.client.auth.currentUser?.id;
    if (uid == null) return;
    final items = await ref.read(financeRepositoryProvider).listAlerts(uid);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = _items.where((a) => !a.isDismissed).toList();
    final unread = visible.where((a) => !a.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: gradientAppBar('Alerts'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 32),
              children: [
                SurfaceCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(children: [
                    const SoftIcon(Icons.notifications_active_outlined, color: AppColors.primary, size: 40, radius: 13),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('$unread unread', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text('${visible.length} alert${visible.length == 1 ? '' : 's'} based on your recent activity',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                      ]),
                    ),
                    TextButton(onPressed: _load, child: const Text('Refresh')),
                  ]),
                ),
                const SizedBox(height: 6),
                if (visible.isEmpty)
                  const EmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: 'All clear',
                    message: 'No alerts right now. We will flag unusual spending, missed EMIs and low buffers here.',
                  )
                else
                  ...visible.map((a) {
                    final critical = a.severity == 'critical';
                    final color = critical ? AppColors.danger : a.severity == 'warning' ? AppColors.warning : AppColors.primary;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SurfaceCard(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            SoftIcon(critical ? Icons.error_outline_rounded : Icons.warning_amber_rounded, color: color, size: 40, radius: 13),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                const SizedBox(height: 2),
                                InfoPill(icon: Icons.circle, label: a.severity.toUpperCase(), color: color),
                              ]),
                            ),
                            IconButton(
                              tooltip: 'Mark as read',
                              onPressed: a.isRead
                                  ? null
                                  : () async {
                                      await ref.read(financeRepositoryProvider).markAlertRead(a.id!);
                                      _load();
                                    },
                              icon: Icon(a.isRead ? Icons.done_all_rounded : Icons.done_rounded, size: 20),
                            ),
                            IconButton(
                              tooltip: 'Dismiss',
                              onPressed: () async {
                                await ref.read(financeRepositoryProvider).dismissAlert(a.id!);
                                _load();
                              },
                              icon: const Icon(Icons.close_rounded, size: 20),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          Text(a.message, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.5)),
                        ]),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
