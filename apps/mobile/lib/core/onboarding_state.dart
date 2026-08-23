import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tracks whether the user has completed (or skipped) onboarding, as a
/// persisted [ValueNotifier] — mirrors `recovery_state.dart`'s pattern.
/// `_OnboardingGate` in `app.dart` reads this to decide whether to show
/// `OnboardingFlow` or fall through to `AuthGate`.
class OnboardingState {
  OnboardingState._();

  static final ValueNotifier<bool> completed = ValueNotifier(false);

  static const _storage = FlutterSecureStorage();
  static const _key = 'mindbridge.onboarding_completed';

  static Future<void> load() async {
    final stored = await _storage.read(key: _key);
    completed.value = stored == 'true';
  }

  static Future<void> set(bool value) async {
    completed.value = value;
    if (value) {
      await _storage.write(key: _key, value: 'true');
    } else {
      await _storage.delete(key: _key);
    }
  }

  /// The mood the user picked during onboarding's first-check-in step,
  /// carried in memory (not persisted — same app session only) so
  /// `HomeScreen` can offer to save it as a real check-in right after
  /// sign-up. Cleared by [clearPending] once offered.
  static double? pendingScore;
  static String? pendingTag;

  static void clearPending() {
    pendingScore = null;
    pendingTag = null;
  }
}
