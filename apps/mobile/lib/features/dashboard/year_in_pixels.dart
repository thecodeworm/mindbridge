import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/elevation.dart';
import '../../core/mood_color.dart';
import '../mood/mood_log_service.dart';

class YearInPixels extends StatefulWidget {
  const YearInPixels({super.key, required this.userId});

  final String userId;

  @override
  State<YearInPixels> createState() => _YearInPixelsState();
}

class _YearInPixelsState extends State<YearInPixels> {
  final _service = MoodLogService(Supabase.instance.client);
  Map<String, int> _dayScores = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _dateStr(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    // Errors are swallowed here by design — this card degrades to an empty
    // grid rather than showing an error state.
    var logs = <MoodLog>[];
    try {
      logs = await _service.getAllLogsForYear(userId: widget.userId);
    } catch (_) {
      // ignored, see above
    }
    if (!mounted) return;
    final scores = <String, int>{};
    for (final log in logs) {
      final key = _dateStr(log.loggedAt);
      final existing = scores[key];
      if (existing == null || log.moodScore > existing) {
        scores[key] = log.moodScore;
      }
    }
    setState(() {
      _dayScores = scores;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppElevation.decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Year in pixels',
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            if (_dayScores.isEmpty) ...[
              Text(
                'Your mood history, visualized',
                style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                'Each square is a day — colors fill in as you log moods.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
            ],
            _PixelGrid(dayScores: _dayScores, cs: cs),
          ],
        ],
      ),
    );
  }
}

class _PixelGrid extends StatelessWidget {
  const _PixelGrid({required this.dayScores, required this.cs});

  final Map<String, int> dayScores;
  final ColorScheme cs;

  String _dateStr(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().toLocal();
    final todayStr = _dateStr(today);

    // Start from 364 days ago (Monday of that week for alignment)
    final startRaw = today.subtract(const Duration(days: 364));
    final weekdayOffset = startRaw.weekday - 1; // 0=Mon
    final start = startRaw.subtract(Duration(days: weekdayOffset));

    final weeks = <List<DateTime>>[];
    var day = start;
    while (!day.isAfter(today)) {
      final week = <DateTime>[];
      for (var d = 0; d < 7; d++) {
        week.add(day.add(Duration(days: d)));
      }
      weeks.add(week);
      day = day.add(const Duration(days: 7));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: weeks.map((week) {
          return Column(
            children: week.map((d) {
              final dStr = _dateStr(d);
              final isFuture = d.isAfter(today);
              final score = dayScores[dStr];
              Color color;
              if (isFuture) {
                color = Colors.transparent;
              } else if (score == null) {
                color = cs.outline.withValues(alpha: 0.4);
              } else {
                color = moodColor(score.toDouble());
              }

              return Tooltip(
                message: score != null
                    ? '$dStr · mood $score'
                    : dStr == todayStr
                    ? 'Today'
                    : dStr,
                child: Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}
