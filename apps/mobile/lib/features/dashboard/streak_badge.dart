import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/motion.dart';
import '../../core/streaks.dart';
import '../mood/mood_log_service.dart';

/// Persists the highest [StreakResult.longest] value already celebrated with
/// a milestone pop, so the animation is rare/earned rather than replaying on
/// every rebuild while the user sits at their current best. Injectable via
/// [StreakBadge.milestoneStore] so widget tests can supply an in-memory fake
/// instead of touching the real secure-storage platform channel.
abstract class MilestoneStore {
  Future<int> lastCelebrated(String userId);
  Future<void> setLastCelebrated(String userId, int value);
}

/// Real implementation — mirrors `theme_controller.dart`'s pattern of a
/// small holder wrapping [FlutterSecureStorage] with a namespaced key.
class SecureMilestoneStore implements MilestoneStore {
  const SecureMilestoneStore();

  static const _storage = FlutterSecureStorage();

  @override
  Future<int> lastCelebrated(String userId) async {
    final raw = await _storage.read(
      key: 'mindbridge.streak.last_celebrated_best.$userId',
    );
    return int.tryParse(raw ?? '') ?? 0;
  }

  @override
  Future<void> setLastCelebrated(String userId, int value) async {
    await _storage.write(
      key: 'mindbridge.streak.last_celebrated_best.$userId',
      value: '$value',
    );
  }
}

String? _defaultCurrentUserId() =>
    Supabase.instance.client.auth.currentUser?.id;

class StreakBadge extends StatefulWidget {
  const StreakBadge({
    super.key,
    required this.logs,
    this.currentUserId,
    this.milestoneStore = const SecureMilestoneStore(),
  });

  final List<MoodLog> logs;

  /// Optional override for the signed-in user id lookup, defaulting to
  /// `Supabase.instance.client.auth.currentUser?.id`. Narrow DI shim so
  /// widget tests never touch `Supabase.instance` (which throws if Supabase
  /// hasn't been initialized) — pass `() => null` to skip the milestone
  /// check entirely, or a fixed id alongside a fake [milestoneStore].
  final String? Function()? currentUserId;

  /// Optional override for milestone persistence, defaulting to the real
  /// [SecureMilestoneStore]. Widget tests inject an in-memory fake.
  final MilestoneStore milestoneStore;

  @override
  State<StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<StreakBadge>
    with SingleTickerProviderStateMixin {
  // Created eagerly in initState (not as a `late final` field initializer)
  // so it always exists while the element is active. build() early-returns
  // SizedBox.shrink() without ever referencing this controller whenever
  // there's no streak yet (longest == 0) — a lazy initializer would then
  // only get created for the first time inside dispose(), by which point
  // the element is deactivated and the vsync TickerMode lookup throws
  // "Looking up a deactivated widget's ancestor is unsafe."
  late final AnimationController _popController;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(vsync: this);
    _checkMilestone();
  }

  @override
  void didUpdateWidget(covariant StreakBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkMilestone();
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  Future<void> _checkMilestone() async {
    final userId = (widget.currentUserId ?? _defaultCurrentUserId)();
    if (userId == null) return;

    final result = computeStreaks(widget.logs);
    if (result.longest == 0) return;

    final stored = await widget.milestoneStore.lastCelebrated(userId);
    if (result.longest > stored) {
      await widget.milestoneStore.setLastCelebrated(userId, result.longest);
      if (!mounted) return;
      // Impulse spring: rest position is 0, a one-shot kick displaces it and
      // the wobbly spring pulls it back — the overshoot on the way back is
      // the "pop." Scale is derived from this in build() below.
      _popController.animateWith(
        SpringSimulation(AppMotion.springWobbly, 0, 0, 8),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final streaks = computeStreaks(widget.logs);
    final window = computePracticeWindow(widget.logs);
    if (streaks.longest == 0) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: _popController,
      builder: (context, child) => Transform.scale(
        scale: 1.0 + _popController.value * 0.06,
        alignment: Alignment.centerLeft,
        child: child,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.spa_outlined, size: 20, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You've practiced ${window.practiced} of ${window.windowDays} days",
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  'Personal best: ${streaks.longest} day${streaks.longest == 1 ? '' : 's'}',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
