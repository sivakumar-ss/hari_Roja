import 'package:intl/intl.dart';

class Money {
  static final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  static String format(num value) => _fmt.format(value);
  static double parse(String s) => double.tryParse(s.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
}
