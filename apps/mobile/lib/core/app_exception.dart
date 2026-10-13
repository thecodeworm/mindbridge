/// Thrown by services on failure. [message] is user-facing and safe to show
/// directly in the UI: raw backend/network text (e.g. "JWT issued at future",
/// a Postgres constraint name, a SocketException) is translated into plain,
/// calm copy by [friendlyErrorMessage] before it ever reaches a widget.
class AppException implements Exception {
  AppException(String raw) : message = friendlyErrorMessage(raw);

  final String message;

  @override
  String toString() => message;
}

/// Maps a raw error string to copy a teenager can act on. Messages that are
/// already plain sentences (the ones services write themselves) pass through
/// unchanged.
String friendlyErrorMessage(String raw) {
  final lower = raw.toLowerCase();
  if (lower.contains('jwt') || lower.contains('token') || lower.contains('session')) {
    return "We couldn't confirm you're signed in. Check your device's date and time, "
        'then sign out and back in.';
  }
  if (lower.contains('socket') ||
      lower.contains('host lookup') ||
      lower.contains('clientexception') ||
      lower.contains('network') ||
      lower.contains('timed out') ||
      lower.contains('timeout') ||
      lower.contains('connection')) {
    return "Can't reach MindBridge right now. Check your connection and try again.";
  }
  if (lower.contains('rate') || lower.contains('429') || lower.contains('too many')) {
    return "You've checked in a lot this hour. Take a breather and try again a bit later.";
  }
  final looksTechnical = lower.contains('exception') ||
      lower.contains('pgrst') ||
      lower.contains('violates') ||
      lower.contains('constraint') ||
      lower.contains('status') ||
      lower.contains('{') ||
      lower.contains('null') ||
      raw.trim().isEmpty;
  if (looksTechnical) {
    return 'Something went wrong on our end. Give it a moment and try again.';
  }
  return raw;
}
