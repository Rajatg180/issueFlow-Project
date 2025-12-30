// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:issueflow_fronted/core/errors/app_exception.dart';

// import '../../../../core/config/app_config.dart';
// import '../../../../core/storage/token_storage.dart';
// import '../models/dashboard_models.dart';

// abstract class DashboardRemoteDataSource {
//   Future<DashboardHomeModel> getDashboardHome();
// }

// class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
//   final http.Client client;
//   final TokenStorage tokenStorage;

//   DashboardRemoteDataSourceImpl({
//     required this.client,
//     required this.tokenStorage,
//   });

//   @override
//   Future<DashboardHomeModel> getDashboardHome() async {
//     final access = await tokenStorage.readAccessToken();
//     if (access == null || access.isEmpty) {
//       throw const AppException("Not authenticated");
//     }

//     final uri = Uri.parse('${AppConfig.baseUrl}/dashboard/home');

//     final res = await client.get(
//       uri,
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $access',
//       },
//     );

//     if (res.statusCode >= 200 && res.statusCode < 300) {
//       final jsonMap = jsonDecode(res.body) as Map<String, dynamic>;
//       return DashboardHomeModel.fromJson(jsonMap);
//     }

//     // Try parse FastAPI error {detail: "..."}
//     try {
//       final err = jsonDecode(res.body);
//       final msg = err is Map && err['detail'] != null
//           ? err['detail'].toString()
//           : 'Dashboard fetch failed';
//       throw AppException(msg, statusCode: res.statusCode);
//     } catch (_) {
//       throw AppException('Dashboard fetch failed (${res.statusCode})', statusCode: res.statusCode);
//     }
//   }
// }


import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:issueflow_fronted/core/errors/app_exception.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/dashboard_models.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardHomeModel> getDashboardHome();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final http.Client client;
  final TokenStorage tokenStorage;

  DashboardRemoteDataSourceImpl({
    required this.client,
    required this.tokenStorage,
  });

  @override
  Future<DashboardHomeModel> getDashboardHome() async {
    // 1) Try with current access token
    final first = await _getHomeOnce();
    if (first != null) return first;

    // 2) If null => it was 401. Refresh and retry once.
    await _refreshAccessToken();

    final second = await _getHomeOnce();
    if (second != null) return second;

    // If still failing after refresh -> treat as logged out / invalid refresh
    throw const AppException("Session expired. Please login again.", statusCode: 401);
  }

  /// Returns DashboardHomeModel on success.
  /// Returns null ONLY when response is 401 (access token expired/invalid).
  Future<DashboardHomeModel?> _getHomeOnce() async {
    final access = await tokenStorage.readAccessToken();
    if (access == null || access.isEmpty) {
      throw const AppException("Not authenticated", statusCode: 401);
    }

    final uri = Uri.parse('${AppConfig.baseUrl}/dashboard/home');

    final res = await client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $access',
      },
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final jsonMap = jsonDecode(res.body) as Map<String, dynamic>;
      return DashboardHomeModel.fromJson(jsonMap);
    }

    if (res.statusCode == 401) {
      // Access token expired/invalid -> caller will refresh and retry
      return null;
    }

    throw _toAppException(res, fallback: "Dashboard fetch failed");
  }

  Future<void> _refreshAccessToken() async {
    final refresh = await tokenStorage.readRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      throw const AppException("Missing refresh token. Please login again.", statusCode: 401);
    }

    final uri = Uri.parse('${AppConfig.baseUrl}/auth/refresh');

    final res = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refresh}),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final newAccess = body['access_token']?.toString();

      if (newAccess == null || newAccess.isEmpty) {
        throw const AppException("Refresh failed: missing access token", statusCode: 401);
      }

      await tokenStorage.saveAccessToken(newAccess);
      return;
    }

    // Refresh failed => user must login again
    throw _toAppException(res, fallback: "Refresh token invalid. Please login again.");
  }

  AppException _toAppException(http.Response res, {required String fallback}) {
    try {
      final err = jsonDecode(res.body);
      final msg = err is Map && err['detail'] != null ? err['detail'].toString() : fallback;
      return AppException(msg, statusCode: res.statusCode);
    } catch (_) {
      return AppException('$fallback (${res.statusCode})', statusCode: res.statusCode);
    }
  }
}
