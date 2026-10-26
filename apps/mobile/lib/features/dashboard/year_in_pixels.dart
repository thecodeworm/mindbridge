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
    // The timeout keeps a hung request from leaving the spinner up forever.
    // Errors are swallowed here by design — this card degrades to an empty
    // grid rather than showing an error state.
    var logs = <MoodLog>[];
    try {
      logs = await _service
          .getAllLogsForYear(userId: widget.userId)
          .timeout(const Duration(seconds: 10));
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
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: AppElevation.decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Year in pixels', style: tt.titleLarge),
          const SizedBox(height: 4),
          Text(
            _dayScores.isEmpty && !_loading
                ? 'One square per day. They fill with color as you check in.'
                : '${_dayScores.length} day${_dayScores.length == 1 ? '' : 's'} logged in the past year. Swipe back to see more.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
          else ...[
            _PixelGrid(dayScores: _dayScores, cs: cs),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Heavy', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(width: 6),
                for (final s in const [1.5, 3.5, 5.5, 7.5, 9.5])
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(color: moodColor(s), borderRadius: BorderRadius.circular(3)),
                  ),
                const SizedBox(width: 6),
                Text('Great', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
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

  static const _cell = 14.0;
  static const _gap = 3.0;
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  String _dateStr(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = _dateStr(today);

    // Start from 364 days ago, aligned back to that week's Monday.
    final startRaw = today.subtract(const Duration(days: 364));
    final start = startRaw.subtract(Duration(days: startRaw.weekday - 1));

    final weeks = <List<DateTime>>[];
    var day = start;
    while (!day.isAfter(today)) {
      weeks.add([for (var d = 0; d < 7; d++) day.add(Duration(days: d))]);
      day = day.add(const Duration(days: 7));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true, // open on the most recent weeks
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int w = 0; w < weeks.length; w++)
            Padding(
              padding: const EdgeInsets.only(right: _gap),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 16,
                    width: _cell,
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      maxWidth: 40,
                      child: (w == 0 || weeks[w].first.month != weeks[w - 1].first.month)
                          ? Text(_months[weeks[w].first.month - 1],
                              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant))
                          : const SizedBox.shrink(),
                    ),
                  ),
                  for (final d in weeks[w])
                    Builder(builder: (context) {
                      final dStr = _dateStr(d);
                      final score = dayScores[dStr];
                      final isFuture = d.isAfter(today);
                      final isToday = dStr == todayStr;
                      return Tooltip(
                        message: score != null ? '$dStr · mood $score' : (isToday ? 'Today' : dStr),
                        child: Container(
                          width: _cell,
                          height: _cell,
                          margin: const EdgeInsets.only(bottom: _gap),
                          decoration: BoxDecoration(
                            color: isFuture
                                ? Colors.transparent
                                : score == null
                                    ? cs.surfaceContainerHigh
                                    : moodColor(score.toDouble()),
                            borderRadius: BorderRadius.circular(3.5),
                            border: isToday ? Border.all(color: cs.primary, width: 1.5) : null,
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
