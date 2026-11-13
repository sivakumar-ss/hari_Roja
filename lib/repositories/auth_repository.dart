import '../models/profile.dart' as app_profile;
import '../services/insforge_service.dart';

class AuthRepository {
  Future<void> signUp(String email, String password, {String? name}) async {
    await InsforgeService.client.auth.signUp(email: email, password: password, name: name);
  }

  Future<void> signIn(String email, String password) async {
    await InsforgeService.client.auth.signIn(email: email, password: password);
  }

  Future<void> signOut() async {
    await InsforgeService.client.auth.signOut();
  }

  dynamic get currentUser => InsforgeService.client.auth.currentUser;

  Stream<dynamic> get onAuthStateChange => InsforgeService.client.auth.onAuthStateChange;

  Future<app_profile.Profile?> fetchProfile(String userId) async {
    final rows = await InsforgeService.client.database.from('profiles').select().eq('user_id', userId).execute();
    if (rows.isEmpty) return null;
    return app_profile.Profile.fromJson(Map<String,dynamic>.from(rows.first));
  }

  Future<void> upsertProfile(app_profile.Profile p) async {
    await InsforgeService.client.database.from('profiles').upsert([p.toJson()], onConflict: 'user_id').execute();
  }
}

