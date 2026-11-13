import 'package:flutter/material.dart';
import '../../services/inflation_engine.dart';
import '../../core/utils/money.dart';
import '../../widgets/ui.dart';

class InflationScreen extends StatefulWidget {
  const InflationScreen({super.key});
  @override
  State<InflationScreen> createState() => _InflationScreenState();
}

class _InflationScreenState extends State<InflationScreen> {
  final _costCtrl = TextEditingController(text: '1000000');
  final _inflCtrl = TextEditingController(text: '6');
  final _yearsCtrl = TextEditingController(text: '5');
  final _contribCtrl = TextEditingController(text: '5000');
  Map<String,double>? _result;

  void _calc() {
    final r = InflationEngine.project(
      currentCost: double.tryParse(_costCtrl.text) ?? 0,
      annualInflation: (double.tryParse(_inflCtrl.text) ?? 6) / 100,
      years: int.tryParse(_yearsCtrl.text) ?? 1,
      monthlyContribution: double.tryParse(_contribCtrl.text) ?? 0,
    );
    setState(() => _result = r);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gradientAppBar('Inflation Analysis'),
      body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        TextField(controller: _costCtrl, decoration: const InputDecoration(labelText: 'Current goal cost'), keyboardType: TextInputType.number),
        TextField(controller: _inflCtrl, decoration: const InputDecoration(labelText: 'Annual inflation %'), keyboardType: TextInputType.number),
        TextField(controller: _yearsCtrl, decoration: const InputDecoration(labelText: 'Years'), keyboardType: TextInputType.number),
        TextField(controller: _contribCtrl, decoration: const InputDecoration(labelText: 'Monthly contribution'), keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _calc, child: const Text('Calculate')),
        if (_result != null) ...[
          const SizedBox(height: 16),
          Text('Current (nominal): ${Money.format(_result!['currentCost']!)}'),
          Text('Future cost (inflation-adjusted): ${Money.format(_result!['futureCost']!)}'),
          Text('Required monthly contribution: ${Money.format(_result!['requiredMonthly']!)}'),
          const SizedBox(height: 8),
          const Text('Projections are estimates, not guarantees.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ])),
    );
  }
}
