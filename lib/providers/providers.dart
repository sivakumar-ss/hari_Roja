import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/insforge_service.dart';
import '../repositories/finance_repository.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());
final financeRepositoryProvider = Provider((ref) => FinanceRepository());

final authStateProvider = StreamProvider((ref) {
  return ref.read(authRepositoryProvider).onAuthStateChange;
});

final currentUserIdProvider = Provider<String?>((ref) {
  try {
    return InsforgeService.client.auth.currentUser?.id;
  } catch (_) {
    return null;
  }
});
