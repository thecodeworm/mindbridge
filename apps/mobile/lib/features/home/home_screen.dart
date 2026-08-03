import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/dashboard/insights_card.dart';
import '../../features/dashboard/mood_trend_chart.dart';
import '../../features/dashboard/streak_badge.dart';
import '../../features/dashboard/weekly_summary_card.dart';
import '../../features/dashboard/year_in_pixels.dart';
import '../help/help_screen.dart';
import '../history/history_list.dart';
import '../mood/mood_log_screen.dart';
import '../mood/mood_log_service.dart';
import '../settings/settings_screen.dart';
import '../toolkit/toolkit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _moodLogService = MoodLogService(Supabase.instance.client);

  List<MoodLog> _logs = [];
  bool _loadingLogs = true;
  int _refreshTick = 0;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final result = await _moodLogService.getMoodLogsInRange(userId: userId, days: 30);
    if (!mounted) return;
    setState(() {
      _logs = result.logs;
      _loadingLogs = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final displayName = user?.userMetadata?['display_name'] as String? ?? 'there';
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Welcome, $displayName',
                      style: Theme.of(context).textTheme.headlineSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ToolkitScreen()),
                        ),
                        icon: const Icon(Icons.bookmark_outline),
                        tooltip: 'My toolkit',
                      ),
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        ),
                        icon: const Icon(Icons.settings_outlined),
                        tooltip: 'Settings',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!_loadingLogs) StreakBadge(logs: _logs),
              const SizedBox(height: 12),
              _loadingLogs
                  ? Container(
                      height: 280,
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cs.outline),
                      ),
                    )
                  : MoodTrendChart(logs: _logs),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MoodLogScreen()),
                  );
                  if (!mounted) return;
                  setState(() => _refreshTick++);
                  _loadLogs();
                },
                child: const Text('Log today\'s mood'),
              ),
              const SizedBox(height: 16),
              if (user != null) ...[
                HistoryList(
                  key: ValueKey(_refreshTick),
                  userId: user.id,
                  onEntryChanged: () {
                    setState(() => _refreshTick++);
                    _loadLogs();
                  },
                ),
                const SizedBox(height: 16),
                InsightsCard(userId: user.id),
                const SizedBox(height: 16),
                WeeklySummaryCard(userId: user.id),
                const SizedBox(height: 16),
                YearInPixels(userId: user.id),
              ],
              const SizedBox(height: 24),
              Divider(color: cs.outline),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpScreen()),
                ),
                child: Text(
                  'Crisis resources & help',
                  style: tt.bodySmall?.copyWith(color: cs.primary),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
