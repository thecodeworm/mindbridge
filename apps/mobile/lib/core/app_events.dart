import 'package:flutter/foundation.dart';

/// Bumped whenever the signed-in user's mood data changes (new check-in,
/// edit, delete). Tabs in `MainShell` stay alive in an IndexedStack, so each
/// one listens to this and reloads instead of relying on a route pop.
final ValueNotifier<int> moodDataVersion = ValueNotifier<int>(0);

void notifyMoodDataChanged() => moodDataVersion.value++;
