import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/issue_model.dart';
import '../models/project_with_issues_model.dart';

abstract class IssuesRemoteDataSource {
  Future<List<ProjectWithIssuesModel>> getProjectsWithIssues();

  Future<IssueModel> createIssue({
    required String projectId,
    required String title,
    String? description,
    required String type,
    required String priority,
    DateTime? dueDate, // ✅ DateTime
  });
}

class IssuesRemoteDataSourceImpl implements IssuesRemoteDataSource {
  final http.Client client;
  final TokenStorage tokenStorage;

  IssuesRemoteDataSourceImpl({
    required this.client,
    required this.tokenStorage,
  });

  String? _toYmd(DateTime? d) {
    if (d == null) return null;
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  @override
  Future<List<ProjectWithIssuesModel>> getProjectsWithIssues() async {
    final token = await tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const AppException("Missing access token");
    }

    final uri = Uri.parse('${AppConfig.baseUrl}/projects/with-issues');

    final res = await client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      String msg = 'Failed to load issues';
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['detail'] != null) {
          msg = decoded['detail'].toString();
        }
      } catch (_) {}
      throw AppException(msg, statusCode: res.statusCode);
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw const AppException('Invalid response format (expected list)');
    }

    return decoded
        .whereType<Map>()
        .map((e) => ProjectWithIssuesModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<IssueModel> createIssue({
    required String projectId,
    required String title,
    String? description,
    required String type,
    required String priority,
    DateTime? dueDate,
  }) async {
    final token = await tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const AppException("Missing access token");
    }

    final uri = Uri.parse('${AppConfig.baseUrl}/projects/$projectId/issues');

    final body = <String, dynamic>{
      "title": title,
      "description": description,
      "type": type,
      "priority": priority,
      "due_date": _toYmd(dueDate), // ✅ send as yyyy-mm-dd (backend expects date)
    };

    final res = await client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      String msg = 'Failed to create issue';
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['detail'] != null) {
          msg = decoded['detail'].toString();
        }
      } catch (_) {}
      throw AppException(msg, statusCode: res.statusCode);
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map) {
      throw const AppException('Invalid response format (expected object)');
    }

    return IssueModel.fromJson(decoded.cast<String, dynamic>());
  }
}
