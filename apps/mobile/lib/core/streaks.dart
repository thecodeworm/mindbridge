// Pure streak computation — mirrors apps/web/src/lib/streaks.ts
// Streak: consecutive calendar days (local timezone) with ≥1 log.

import '../features/mood/mood_log_service.dart';

class StreakResult {
  const StreakResult({required this.current, required this.longest});
  final int current;
  final int longest;
}

String _localDateStr(DateTime dt) {
  final local = dt.toLocal();
  final y = local.year.toString();
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

StreakResult computeStreaks(List<MoodLog> logs) {
  if (logs.isEmpty) return const StreakResult(current: 0, longest: 0);

  final days = logs.map((l) => _localDateStr(l.loggedAt)).toSet().toList()..sort();

  int longest = 1;
  int run = 1;
  for (int i = 1; i < days.length; i++) {
    final prev = DateTime.parse(days[i - 1]);
    final curr = DateTime.parse(days[i]);
    final diff = curr.difference(prev).inDays;
    if (diff == 1) {
      run++;
      if (run > longest) longest = run;
    } else {
      run = 1;
    }
  }

  final todayStr = _localDateStr(DateTime.now());
  final latestStr = days.last;
  final latestDate = DateTime.parse(latestStr);
  final todayDate = DateTime.parse(todayStr);
  final diffToToday = todayDate.difference(latestDate).inDays;

  int current = 0;
  if (diffToToday <= 1) {
    current = 1;
    for (int i = days.length - 2; i >= 0; i--) {
      final a = DateTime.parse(days[i]);
      final b = DateTime.parse(days[i + 1]);
      if (b.difference(a).inDays == 1) {
        current++;
      } else {
        break;
      }
    }
  }

  return StreakResult(current: current, longest: current > longest ? current : longest);
}
