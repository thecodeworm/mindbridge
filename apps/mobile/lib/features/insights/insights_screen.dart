import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_events.dart';
import '../../core/elevation.dart';
import '../../widgets/crisis_fab.dart';
import '../dashboard/insights_card.dart';
import '../dashboard/mood_trend_chart.dart';
import '../dashboard/weekly_summary_card.dart';
import '../dashboard/year_in_pixels.dart';
import '../mood/mood_log_service.dart';

/// "Insights" tab: the trend chart, the AI weekly reflection, activity
/// correlations and the year grid, moved off Today so the front door stays
/// about checking in.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final _service = MoodLogService(Supabase.instance.client);
  List<MoodLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    moodDataVersion.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    moodDataVersion.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    var logs = <MoodLog>[];
    try {
      logs = await _service.getMoodLogsInRange(userId: userId, days: 30);
    } catch (_) {
      // Degrades to the chart's own empty state.
    }
    if (!mounted) return;
    setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        actions: const [HelpAction()],
      ),
      body: userId == null
          ? const SizedBox.shrink()
          : RefreshIndicator(
              onRefresh: () async => notifyMoodDataChanged(),
              child: ValueListenableBuilder<int>(
                valueListenable: moodDataVersion,
                builder: (context, version, _) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    if (_loading)
                      Container(height: 300, decoration: AppElevation.decoration(context))
                    else
                      MoodTrendChart(logs: _logs),
                    const SizedBox(height: 16),
                    WeeklySummaryCard(key: ValueKey('weekly-$version'), userId: userId),
                    const SizedBox(height: 16),
                    InsightsCard(key: ValueKey('insights-$version'), userId: userId),
                    const SizedBox(height: 16),
                    YearInPixels(key: ValueKey('pixels-$version'), userId: userId),
                  ],
                ),
              ),
            ),
    );
  }
}
