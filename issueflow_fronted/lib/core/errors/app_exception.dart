/// Base application exception used across data/domain layers.
///
/// Purpose:
/// - Wrap backend/API errors
/// - Avoid throwing raw Exception/String
/// - Keep error handling consistent in Bloc/UI
class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;
}
