import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/token_pair_model.dart';
import '../models/user_me_model.dart';

class AuthRemoteDataSource {
  final http.Client client;
  AuthRemoteDataSource({required this.client});

  Uri _u(String path) => Uri.parse("${AppConfig.baseUrl}$path");

  String? _extractDetail(String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map && j["detail"] != null) return j["detail"].toString();
    } catch (_) {}
    return null;
  }

  Future<TokenPairModel> register(String username, String email, String password) async {
    final res = await client.post(
      _u("/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
      }),
    );

    if (res.statusCode != 200) {
      throw AppException(_extractDetail(res.body) ?? "Registration failed");
    }
    return TokenPairModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }


  Future<TokenPairModel> login(String email, String password) async {
    final res = await client.post(
      _u("/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    if (res.statusCode != 200) {
      throw AppException(_extractDetail(res.body) ?? "Invalid email or password");
    }
    return TokenPairModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<String> refreshAccessToken(String refreshToken) async {
    final res = await client.post(
      _u("/auth/refresh"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refresh_token": refreshToken}),
    );

    if (res.statusCode != 200) {
      throw AppException(_extractDetail(res.body) ?? "Refresh token invalid");
    }

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return j["access_token"] as String;
  }

  Future<void> logout(String refreshToken) async {
    await client.post(
      _u("/auth/logout"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refresh_token": refreshToken}),
    );
  }

  Future<UserMeModel> me(String accessToken) async {
    final res = await client.get(
      _u("/auth/me"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
    );

    if (res.statusCode != 200) {
      throw AppException(
        _extractDetail(res.body) ?? "Not authenticated",
        statusCode: res.statusCode,
      );
    }

    return UserMeModel.fromJson(jsonDecode(res.body));
  }


  Future<TokenPairModel> firebaseLogin(String firebaseIdToken) async {
    final res = await client.post(
      _u("/auth/firebase"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_token": firebaseIdToken}),
    );

    if (res.statusCode != 200) {
      throw AppException(_extractDetail(res.body) ?? "Firebase authentication failed");
    }

    return TokenPairModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }


}
