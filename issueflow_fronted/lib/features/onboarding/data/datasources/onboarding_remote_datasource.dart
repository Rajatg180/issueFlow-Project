import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:issueflow_fronted/core/errors/app_exception.dart';
import 'package:issueflow_fronted/features/onboarding/data/models/onboarding_result_model.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/storage/token_storage.dart';

abstract class OnboardingRemoteDataSource {
  Future<void> completeOnboarding();
  Future<OnboardingResultModel> setup({
    required String projectName,
    required String projectKey,
    String? projectDescription,
    required List<String> invites,
    required String issueTitle,
    String? issueDescription,
    required String issueType, // task/bug/feature
    required String issuePriority, // low/medium/high
  });
}

class OnboardingRemoteDataSourceImpl implements OnboardingRemoteDataSource {
  final http.Client client;
  final TokenStorage tokenStorage;

  OnboardingRemoteDataSourceImpl({
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

  @override
  Future<OnboardingResultModel> setup({
    required String projectName,
    required String projectKey,
    String? projectDescription,
    required List<String> invites,
    required String issueTitle,
    String? issueDescription,
    required String issueType, // task/bug/feature
    required String issuePriority, // low/medium/high
  }) async {
    final access = await tokenStorage.readAccessToken();
    if (access == null) {
      throw const AppException("Not authenticated", statusCode: 401);
    }
    final res = await client.post(
      _u("/onboarding/setup"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $access",
      },
      body: jsonEncode({
        "project": {
          "name": projectName,
          "key": projectKey,
          "description": projectDescription,
        },
        "invites": invites,
        "first_issue": {
          "title": issueTitle,
          "description": issueDescription,
          "type": issueType,
          "priority": issuePriority,
        },
      }),
    );

    if (res.statusCode != 200) {
      throw AppException(
        _extractDetail(res.body) ?? "Onboarding setup failed",
        statusCode: res.statusCode,
      );
    }

    return OnboardingResultModel.fromJson(jsonDecode(res.body));
  }

  @override
  Future<void> completeOnboarding() async {
    final access = await tokenStorage.readAccessToken();
    if (access == null) {
      throw Exception("Not authenticated");
    }

    final res = await client.post(
      _u("/onboarding/complete"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $access",
      },
      body: jsonEncode({}), // empty body, just to be explicit
    );

    if (res.statusCode != 200) {
      throw AppException(
        _extractDetail(res.body) ?? "Failed to complete onboarding",
        statusCode: res.statusCode,
      );
    }
  }
}
