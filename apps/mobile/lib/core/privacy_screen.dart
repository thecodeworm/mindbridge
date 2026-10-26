import 'package:flutter/services.dart';

/// Android only: toggles FLAG_SECURE (blank recents thumbnail, no screenshots)
/// through MainActivity. A no-op on iOS and in tests, where no handler exists.
class PrivacyScreen {
  PrivacyScreen._();

  static const _channel = MethodChannel('com.mindbridge.mindbridge/privacy');

  static Future<void> setSecure(bool secure) async {
    try {
      await _channel.invokeMethod<void>('setSecure', {'secure': secure});
    } on MissingPluginException {
      // iOS / unit tests.
    } on PlatformException {
      // Never let a cosmetic privacy feature break the app.
    }
  }
}
