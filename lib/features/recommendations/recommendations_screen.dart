import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/insforge_service.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';

class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});
  @override
  ConsumerState<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> {
  List<Recommendation> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final uid = InsforgeService.client.auth.currentUser?.id;
    if (uid == null) return;
    final items = await ref.read(financeRepositoryProvider).listRecommendations(uid);
    setState(() { _items = items; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gradientAppBar('Recommendations'),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final r = _items[i];
          return Card(child: ListTile(
            title: Text(r.title),
            subtitle: Text('${r.reason}\nAction: ${r.recommendedAction}'),
            trailing: PopupMenuButton<String>(onSelected: (v) async {
              await ref.read(financeRepositoryProvider).updateRecommendationStatus(r.id!, v);
              _load();
            }, itemBuilder: (_) => const [PopupMenuItem(value: 'dismissed', child: Text('Dismiss')), PopupMenuItem(value: 'done', child: Text('Done'))]),
          ));
        },
      ),
    );
  }
}
