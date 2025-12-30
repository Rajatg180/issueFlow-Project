import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeStorage {
  static const _kThemeMode = "theme_mode"; // "dark" | "light" | "system"
  final FlutterSecureStorage _storage;

  ThemeStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveThemeMode(String mode) => _storage.write(key: _kThemeMode, value: mode);

  Future<String?> readThemeMode() => _storage.read(key: _kThemeMode);
}
