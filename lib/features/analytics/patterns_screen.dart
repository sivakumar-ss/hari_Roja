import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';

class PatternsScreen extends ConsumerStatefulWidget {
  const PatternsScreen({super.key});
  @override
  ConsumerState<PatternsScreen> createState() => _PatternsScreenState();
}

class _PatternsScreenState extends ConsumerState<PatternsScreen> {
  List<Map<String,dynamic>> _patterns = [];
  String _tier = 'Tier 2';
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final items = await ref.read(financeRepositoryProvider).getPatterns(_tier);
    setState(() { _patterns = items; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gradientAppBar('Tier Pattern Analysis'),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(8), child: DropdownButton<String>(value: _tier, items: ['Tier 1','Tier 2','Tier 3'].map((t)=>DropdownMenuItem(value:t,child:Text(t))).toList(), onChanged: (v){ setState(()=>_tier=v!); _load(); })),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : ListView.builder(itemCount: _patterns.length, itemBuilder: (_, i) {
          final p = _patterns[i];
          return ListTile(title: Text('${p['category']} - ${p['metric']}'), subtitle: Text('Avg: ${p['avg_value']} (n=${p['sample_size']})'));
        })),
        const Padding(padding: EdgeInsets.all(8), child: Text('Comparisons are anonymized statistical patterns, not financial advice.', style: TextStyle(fontSize: 11, color: Colors.grey))),
      ]),
    );
  }
}
