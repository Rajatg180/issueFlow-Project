import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/project_model.dart';

class ProjectsRemoteDataSource {
  final http.Client client;
  final TokenStorage tokenStorage;

  ProjectsRemoteDataSource({
    required this.client,
    required this.tokenStorage,
  });

  Uri _u(String path) => Uri.parse("${AppConfig.baseUrl}$path");

  String? _extractDetail(String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map && j["detail"] != null) return j["detail"].toString();
    } catch (_) {}
    return null;
  }

  Future<Map<String, String>> _authHeaders() async {
    final accessToken = await tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw const AppException("Not authenticated", statusCode: 401);
    }
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $accessToken",
    };
  }

  Future<void> _refreshAccessToken() async {
    final refreshToken = await tokenStorage.requireRefreshToken();

    final res = await client.post(
      _u("/auth/refresh"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refresh_token": refreshToken}),
    );

    if (res.statusCode != 200) {
      await tokenStorage.clear();
      throw AppException(
        _extractDetail(res.body) ?? "Session expired. Please login again.",
        statusCode: res.statusCode,
      );
    }

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final newAccess = (j["access_token"] ?? "").toString();
    await tokenStorage.saveAccessToken(newAccess);
  }

  Future<http.Response> _runWithAutoRefresh(
    Future<http.Response> Function() request,
  ) async {
    final res = await request();
    if (res.statusCode != 401) return res;

    await _refreshAccessToken();
    return request();
  }

  Future<List<ProjectModel>> listProjects() async {
    final res = await _runWithAutoRefresh(() async {
      final headers = await _authHeaders();
      return client.get(_u("/projects"), headers: headers);
    });

    if (res.statusCode != 200) {
      throw AppException(
        _extractDetail(res.body) ?? "Failed to load projects",
        statusCode: res.statusCode,
      );
    }

    final decoded = jsonDecode(res.body);
    return ProjectModel.listFromJson(decoded);
  }

  Future<ProjectModel> createProject({
    required String name,
    required String key,
    String? description,
  }) async {
    final res = await _runWithAutoRefresh(() async {
      final headers = await _authHeaders();
      return client.post(
        _u("/projects"),
        headers: headers,
        body: jsonEncode({
          "name": name,
          "key": key,
          "description": description,
        }),
      );
    });

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw AppException(
        _extractDetail(res.body) ?? "Failed to create project",
        statusCode: res.statusCode,
      );
    }

    return ProjectModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteProject(String projectId) async {
    final res = await _runWithAutoRefresh(() async {
      final headers = await _authHeaders();
      return client.delete(_u("/projects/$projectId"), headers: headers);
    });

    if (res.statusCode != 200) {
      throw AppException(
        _extractDetail(res.body) ?? "Failed to delete project",
        statusCode: res.statusCode,
      );
    }
  }

  // ✅ NEW: update preference (favorite/pin)
  Future<ProjectModel> updatePreference(
    String projectId, {
    bool? isFavorite,
    bool? isPinned,
  }) async {
    // send ONLY provided fields
    final body = <String, dynamic>{};
    if (isFavorite != null) body["is_favorite"] = isFavorite;
    if (isPinned != null) body["is_pinned"] = isPinned;

    final res = await _runWithAutoRefresh(() async {
      final headers = await _authHeaders();
      return client.patch(
        _u("/projects/$projectId/preference"),
        headers: headers,
        body: jsonEncode(body),
      );
    });

    if (res.statusCode != 200) {
      throw AppException(
        _extractDetail(res.body) ?? "Failed to update preference",
        statusCode: res.statusCode,
      );
    }

    return ProjectModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
