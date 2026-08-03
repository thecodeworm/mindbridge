import 'package:flutter/material.dart';
import '../../core/streaks.dart';
import '../mood/mood_log_service.dart';

class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.logs});

  final List<MoodLog> logs;

  @override
  Widget build(BuildContext context) {
    final result = computeStreaks(logs);
    if (result.current == 0 && result.longest == 0) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.current > 0
                      ? '${result.current}-day streak'
                      : 'Start a new streak today',
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (result.longest > 0)
                  Text(
                    'Longest: ${result.longest} day${result.longest == 1 ? '' : 's'}',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
