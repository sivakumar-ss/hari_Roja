import 'package:insforge_flutter/insforge_flutter.dart';
import '../core/config/app_config.dart';

class InsforgeService {
  static Future<void> init() async {
    await Insforge.initialize(
      url: AppConfig.insforgeUrl,
      anonKey: AppConfig.anonKey,
      apiKey: AppConfig.apiKey,
    );
  }

  static dynamic get client => Insforge.instance;
}
