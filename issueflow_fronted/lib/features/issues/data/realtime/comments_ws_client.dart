import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/storage/token_storage.dart';


class CommentsWsClient {
  final TokenStorage tokenStorage;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  CommentsWsClient({required this.tokenStorage});

  bool get isConnected => _channel != null;

  /// Convert your baseUrl -> wsUrl.
  /// Example:
  ///   http://127.0.0.1:8000   -> ws://127.0.0.1:8000
  ///   https://api.domain.com  -> wss://api.domain.com
  Uri _toWsUri(String path, Map<String, String> query) {
    final base = Uri.parse(AppConfig.baseUrl);
    final scheme = (base.scheme == 'https') ? 'wss' : 'ws';

    return Uri(
      scheme: scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: path,
      queryParameters: query,
    );
  }

  /// Connect and start streaming events.
  /// onEvent receives decoded json map from server.
  Future<void> connect({
    required String projectId,
    required String issueId,
    required void Function(Map<String, dynamic> event) onEvent,
    void Function(Object error)? onError,
    void Function()? onDone,
  }) async {
    // Close any previous connection first
    await disconnect();

    final token = await tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception("Not authenticated (missing access token)");
    }

    final uri = _toWsUri("/ws/projects/$projectId/issues/$issueId/comments", {
      "token": token,
    });

    _channel = WebSocketChannel.connect(uri);

    _sub = _channel!.stream.listen(
      (data) {
        try {
          final decoded = jsonDecode(data.toString());
          if (decoded is Map<String, dynamic>) {
            onEvent(decoded);
          }
        } catch (_) {
          // ignore invalid messages
        }
      },
      onError: (e) {
        onError?.call(e);
      },
      onDone: () {
        onDone?.call();
      },
      cancelOnError: true,
    );
  }

  /// Optional keep-alive
  void sendPing() {
    _channel?.sink.add(jsonEncode({"type": "ping"}));
  }

  Future<void> disconnect() async {
    try {
      await _sub?.cancel();
    } catch (_) {}
    _sub = null;

    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }
}
