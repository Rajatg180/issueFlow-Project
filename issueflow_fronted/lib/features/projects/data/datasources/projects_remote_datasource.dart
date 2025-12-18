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

  Future<List<ProjectModel>> listProjects() async {
    final accessToken = await tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw AppException("Not authenticated");
    }

    final res = await client.get(
      _u("/projects"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
    );

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
    final accessToken = await tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw AppException("Not authenticated");
    }

    final res = await client.post(
      _u("/projects"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: jsonEncode({
        "name": name,
        "key": key,
        "description": description,
      }),
    );

    // Your backend returns 200 for create currently (FastAPI default),
    // but allow 201 too just in case.
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw AppException(
        _extractDetail(res.body) ?? "Failed to create project",
        statusCode: res.statusCode,
      );
    }

    return ProjectModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
