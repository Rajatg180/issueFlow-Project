import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/issue_comment_model.dart';
import '../models/issue_model.dart';
import '../models/project_user_model.dart';
import '../models/project_with_issues_model.dart';

abstract class IssuesRemoteDataSource {
  Future<List<ProjectWithIssuesModel>> getProjectsWithIssues();

  Future<IssueModel> createIssue({
    required String projectId,
    required String title,
    String? description,
    required String type,
    required String priority,
    DateTime? dueDate,
  });

  Future<List<ProjectUserModel>> getProjectUsers({required String projectId});

  Future<void> updateIssue({
    required String projectId,
    required String issueId,
    required String title,
    String? description,
    required String type,
    required String priority,
    required String status,
    DateTime? dueDate,
    String? assigneeId,
    required String reporterId,
  });

  Future<void> deleteIssue({
    required String projectId,
    required String issueId,
  });

  Future<List<IssueCommentModel>> getIssueComments({
    required String projectId,
    required String issueId,
  });

  Future<IssueCommentModel> createIssueComment({
    required String projectId,
    required String issueId,
    required String body,
  });

  // ✅ NEW
  Future<IssueCommentModel> updateIssueComment({
    required String projectId,
    required String issueId,
    required String commentId,
    required String body,
  });

  // ✅ NEW
  Future<void> deleteIssueComment({
    required String projectId,
    required String issueId,
    required String commentId,
  });
}

class IssuesRemoteDataSourceImpl implements IssuesRemoteDataSource {
  final http.Client client;
  final TokenStorage tokenStorage;

  IssuesRemoteDataSourceImpl({
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
    if (newAccess.isEmpty) {
      await tokenStorage.clear();
      throw const AppException("Invalid refresh response", statusCode: 401);
    }

    await tokenStorage.saveAccessToken(newAccess);
  }

  Future<http.Response> _runWithAutoRefresh(
    Future<http.Response> Function() request,
  ) async {
    final res = await request();
    if (res.statusCode != 401) return res;

    await _refreshAccessToken();
    final retry = await request();

    if (retry.statusCode == 401) {
      await tokenStorage.clear();
      throw const AppException("Session expired. Please login again.", statusCode: 401);
    }
    return retry;
  }

  String? _toYmd(DateTime? d) {
    if (d == null) return null;
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  @override
  Future<List<ProjectWithIssuesModel>> getProjectsWithIssues() async {
    final res = await _runWithAutoRefresh(() async {
      final headers = await _authHeaders();
      return client.get(_u("/projects/with-issues"), headers: headers);
    });

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AppException(
        _extractDetail(res.body) ?? "Failed to load issues",
        statusCode: res.statusCode,
      );
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
    final res = await _runWithAutoRefresh(() async {
      final headers = await _authHeaders();
      return client.post(
        _u("/projects/$projectId/issues"),
        headers: headers,
        body: jsonEncode({
          "title": title,
          "description": description,
          "type": type,
          "priority": priority,
          "due_date": _toYmd(dueDate),
        }),
      );
    });

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AppException(
        _extractDetail(res.body) ?? "Failed to create issue",
        statusCode: res.statusCode,
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map) {
      throw const AppException('Invalid response format (expected object)');
    }

    return IssueModel.fromJson(decoded.cast<String, dynamic>());
  }

  @override
  Future<List<ProjectUserModel>> getProjectUsers({
    required String projectId,
  }) async {
    final res = await _runWithAutoRefresh(() async {
      final headers = await _authHeaders();
      return client.get(_u("/users/projects/$projectId"), headers: headers);
    });

    if (res.statusCode != 200) {
      throw AppException(
        _extractDetail(res.body) ?? "Failed to load project users",
        statusCode: res.statusCode,
      );
    }

    final data = jsonDecode(res.body);
    if (data is! Map<String, dynamic>) {
      throw const AppException("Invalid response format for users");
    }

    final list = (data['users'] as List<dynamic>? ?? []);
    return list
        .map((e) => ProjectUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> updateIssue({
    required String projectId,
    required String issueId,
    required String title,
    String? description,
    required String type,
    required String priority,
    required String status,
    DateTime? dueDate,
    String? assigneeId,
    required String reporterId,
  }) async {
    final res = await _runWithAutoRefresh(() async {
      final headers = await _authHeaders();
      return client.patch(
        _u("/projects/$projectId/issues/$issueId"),
        headers: headers,
        body: jsonEncode({
          "title": title,
          "description": description,
          "type": type,
          "priority": priority,
          "status": status,
          "due_date": _toYmd(dueDate),
          "assignee_id": assigneeId,
          "reporter_id": reporterId,
        }),
      );
    });

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AppException(
        _extractDetail(res.body) ?? "Failed to update issue",
        statusCode: res.statusCode,
      );
    }
  }

  @override
  Future<void> deleteIssue({
    required String projectId,
    required String issueId,
  }) async {
    final res = await _runWithAutoRefresh(() async {
      final headers = await _authHeaders();
      return client.delete(
        _u("/projects/$projectId/issues/$issueId"),
        headers: headers,
      );
    });

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AppException(
        _extractDetail(res.body) ?? "Failed to delete issue",
        statusCode: res.statusCode,
      );
    }
  }

  @override
  Future<List<IssueCommentModel>> getIssueComments({
    required String projectId,
    required String issueId,
  }) async {
    final res = await _runWithAutoRefresh(() async {
      final headers = await _authHeaders();
      return client.get(
        _u("/projects/$projectId/issues/$issueId/comments"),
        headers: headers,
      );
    });

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AppException(
        _extractDetail(res.body) ?? "Failed to load comments",
        statusCode: res.statusCode,
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw const AppException('Invalid response format (expected list)');
    }

    return decoded
        .whereType<Map>()
        .map((e) => IssueCommentModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<IssueCommentModel> createIssueComment({
    required String projectId,
    required String issueId,
    required String body,
  }) async {
    final res = await _runWithAutoRefresh(() async {
      final headers = await _authHeaders();
      return client.post(
        _u("/projects/$projectId/issues/$issueId/comments"),
        headers: headers,
        body: jsonEncode({"body": body}),
      );
    });

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AppException(
        _extractDetail(res.body) ?? "Failed to create comment",
        statusCode: res.statusCode,
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map) {
      throw const AppException('Invalid response format (expected object)');
    }

    return IssueCommentModel.fromJson(decoded.cast<String, dynamic>());
  }


  @override
  Future<IssueCommentModel> updateIssueComment({
    required String projectId,
    required String issueId,
    required String commentId,
    required String body,
  }) async {
    final res = await _runWithAutoRefresh(() async {
      final headers = await _authHeaders();
      return client.patch(
        _u("/projects/$projectId/issues/$issueId/comments/$commentId"),
        headers: headers,
        body: jsonEncode({"body": body}),
      );
    });

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AppException(
        _extractDetail(res.body) ?? "Failed to edit comment",
        statusCode: res.statusCode,
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map) {
      throw const AppException('Invalid response format (expected object)');
    }

    return IssueCommentModel.fromJson(decoded.cast<String, dynamic>());
  }

  @override
  Future<void> deleteIssueComment({
    required String projectId,
    required String issueId,
    required String commentId,
  }) async {
    final res = await _runWithAutoRefresh(() async {
      final headers = await _authHeaders();
      return client.delete(
        _u("/projects/$projectId/issues/$issueId/comments/$commentId"),
        headers: headers,
      );
    });

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AppException(
        _extractDetail(res.body) ?? "Failed to delete comment",
        statusCode: res.statusCode,
      );
    }
  }
}
