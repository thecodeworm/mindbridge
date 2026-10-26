import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'privacy_screen.dart';

const _kKey = 'app_lock_enabled';
const _storage = FlutterSecureStorage();

class AppLockState {
  AppLockState._();

  static final enabled = ValueNotifier<bool>(false);
  static final locked = ValueNotifier<bool>(false);

  /// True while the app is inactive (iOS app switcher, notification shade):
  /// the UI draws an opaque cover so journal text is not captured in the
  /// snapshot. It does not lock; locking happens when the app is paused.
  static final obscured = ValueNotifier<bool>(false);

  /// True while the system biometric prompt is on screen. That prompt makes
  /// the app go inactive/paused, which must not immediately re-lock it.
  static bool authenticating = false;

  /// [hasSession] is false for signed-out users, who have nothing to protect
  /// and would only be shown a lock screen with nothing behind it.
  static Future<void> init({required bool hasSession}) async {
    final val = await _storage.read(key: _kKey);
    enabled.value = val == 'true';
    // Cold start counts as a fresh open: a force-quit and relaunch must not
    // bypass the lock.
    locked.value = enabled.value && hasSession;
    await PrivacyScreen.setSecure(enabled.value);
  }

  static Future<void> setEnabled(bool value) async {
    enabled.value = value;
    await _storage.write(key: _kKey, value: value.toString());
    await PrivacyScreen.setSecure(value);
  }

  static void lock() {
    if (enabled.value && !authenticating) locked.value = true;
  }

  static void unlock() {
    locked.value = false;
  }
}
