import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/storage/token_storage.dart';

abstract class OnboardingRemoteDataSource {
  Future<void> completeOnboarding();
}

class OnboardingRemoteDataSourceImpl implements OnboardingRemoteDataSource {
  final http.Client client;
  final TokenStorage tokenStorage;

  OnboardingRemoteDataSourceImpl({
    required this.client,
    required this.tokenStorage,
  });

  @override
  Future<void> completeOnboarding() async {
    final access = await tokenStorage.readAccessToken();
    if (access == null) {
      throw Exception("Not authenticated");
    }

    final uri = Uri.parse("${AppConfig.baseUrl}/onboarding/complete");

    final res = await client.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $access",
      },
      body: jsonEncode({}), // empty body, just to be explicit
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return;
    }

    throw Exception("Failed to complete onboarding (${res.statusCode}): ${res.body}");
  }
}
