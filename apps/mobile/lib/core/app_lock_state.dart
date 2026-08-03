import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kKey = 'app_lock_enabled';
const _storage = FlutterSecureStorage();

class AppLockState {
  AppLockState._();

  static final enabled = ValueNotifier<bool>(false);
  static final locked = ValueNotifier<bool>(false);

  static Future<void> init() async {
    final val = await _storage.read(key: _kKey);
    enabled.value = val == 'true';
  }

  static Future<void> setEnabled(bool value) async {
    enabled.value = value;
    await _storage.write(key: _kKey, value: value.toString());
  }

  static void lock() {
    if (enabled.value) locked.value = true;
  }

  static void unlock() {
    locked.value = false;
  }
}
