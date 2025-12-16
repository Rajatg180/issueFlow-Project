import 'package:flutter/foundation.dart';

class AppConfig {
  // Change this to your PC LAN IP (for real devices)
  static const String _lanIpBaseUrl = "http://192.168.1.5:8000";

  // Localhost for web/desktop when backend runs on same machine
  static const String _localBaseUrl = "http://127.0.0.1:8000";

  static String get baseUrl {
    // Flutter Web runs on your PC → use localhost
    if (kIsWeb) return _localBaseUrl;

    // Mobile real device → use LAN IP
    return _lanIpBaseUrl;
  }
}
