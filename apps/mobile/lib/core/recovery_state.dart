import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tracks whether the current Supabase session is a password-recovery
/// session, as a persisted [ValueNotifier]. `AuthGate` reads this instead of
/// the transient `AuthChangeEvent.passwordRecovery` stream event, which
/// fires once and is missed by any later emission — `tokenRefreshed`,
/// `userUpdated` (fired by `updatePassword` itself), or `initialSession`
/// after an app relaunch — all of which carry a live session that would
/// otherwise fall through to `HomeScreen`.
class RecoveryState {
  RecoveryState._();

  static final ValueNotifier<bool> isRecovery = ValueNotifier(false);

  static const _storage = FlutterSecureStorage();
  static const _key = 'mindbridge.recovery_session';

  static Future<void> load() async {
    final stored = await _storage.read(key: _key);
    isRecovery.value = stored == 'true';
  }

  static Future<void> set(bool value) async {
    isRecovery.value = value;
    if (value) {
      await _storage.write(key: _key, value: 'true');
    } else {
      await _storage.delete(key: _key);
    }
  }
}
