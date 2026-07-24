import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Holds the user's theme override (light/dark/system) as a global
/// [ValueNotifier] so `app.dart`'s `MaterialApp` can react live, and
/// persists it via the same secure-storage mechanism as the Supabase
/// session (see `secure_storage.dart`).
class ThemeController {
  ThemeController._();

  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  static const _storage = FlutterSecureStorage();
  static const _key = 'mindbridge.theme_mode';

  static Future<void> load() async {
    final stored = await _storage.read(key: _key);
    mode.value = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static Future<void> setMode(ThemeMode value) async {
    mode.value = value;
    await _storage.write(key: _key, value: value.name);
  }
}
