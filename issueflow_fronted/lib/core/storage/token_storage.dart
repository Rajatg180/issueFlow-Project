import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _kAccess = "access_token";
  static const _kRefresh = "refresh_token";

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _kAccess, value: accessToken);
    await _storage.write(key: _kRefresh, value: refreshToken);
  }

  Future<String?> readAccessToken() => _storage.read(key: _kAccess);
  Future<String?> readRefreshToken() => _storage.read(key: _kRefresh);

  Future<void> saveAccessToken(String accessToken) async {
    await _storage.write(key: _kAccess, value: accessToken);
  }

  Future<String> requireRefreshToken() async {
    final rt = await readRefreshToken();
    if (rt == null || rt.isEmpty) {
      throw Exception("Missing refresh token");
    }
    return rt;
  }

  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}
