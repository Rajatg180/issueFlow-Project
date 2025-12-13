import '../../domain/entities/token_pair.dart';

class TokenPairModel extends TokenPair {
  const TokenPairModel({
    required super.accessToken,
    required super.refreshToken,
    super.tokenType = "bearer",
  });

  factory TokenPairModel.fromJson(Map<String, dynamic> json) {
    return TokenPairModel(
      accessToken: json["access_token"] as String,
      refreshToken: json["refresh_token"] as String,
      tokenType: (json["token_type"] ?? "bearer") as String,
    );
  }
}
