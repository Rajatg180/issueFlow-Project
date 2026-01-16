import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class BackendWarmup {
  static Future<void> ping() async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/health');

      // fire-and-forget with timeout
      await http.get(uri).timeout(
        const Duration(seconds: 8),
      );
    } catch (_) {
      // swallow errors — this should NEVER block app startup
    }
  }
}
