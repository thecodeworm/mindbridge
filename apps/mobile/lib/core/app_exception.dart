/// Thrown by services on failure. [message] is user-facing and safe to show
/// directly in the UI — it mirrors the underlying PostgrestException /
/// FunctionException message.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}
