import '../models/profile.dart';

class SchemeEligibility {
  static Map<String, bool> evaluate(Profile p, {required double monthlyIncome}) {
    final age = p.age ?? 30;
    final res = <String, bool>{};
    res['PMJDY'] = true;
    res['PMJJBY'] = age >= 18 && age <= 50;
    res['PMSBY'] = age >= 18 && age <= 70;
    res['APY'] = age >= 18 && age <= 40;
    res['PPF'] = true;
    res['POMIS'] = true;
    res['SCHOLARSHIP'] = (p.age ?? 30) <= 25; // students
    res['SSY'] = false;
    return res;
  }
}
