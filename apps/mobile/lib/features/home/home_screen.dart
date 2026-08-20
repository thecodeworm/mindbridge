import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/elevation.dart';
import '../../core/onboarding_state.dart';
import '../../features/dashboard/insights_card.dart';
import '../../features/dashboard/mood_trend_chart.dart';
import '../../features/dashboard/streak_badge.dart';
import '../../features/dashboard/weekly_summary_card.dart';
import '../../features/dashboard/year_in_pixels.dart';
import '../../widgets/crisis_fab.dart';
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
  bool _showOnboardingNudge = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _openMoodLog({double? initialScore, String? initialTag}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MoodLogScreen(initialScore: initialScore, initialTag: initialTag),
      ),
    );
    if (!mounted) return;
    setState(() => _refreshTick++);
    _loadLogs();
  }

  void _dismissOnboardingNudge() {
    OnboardingState.clearPending();
    setState(() => _showOnboardingNudge = false);
  }

  Future<void> _loadLogs() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final result = await _moodLogService.getMoodLogsInRange(
      userId: userId,
      days: 30,
    );
    if (!mounted) return;
    setState(() {
      _logs = result.logs;
      _loadingLogs = false;
      _showOnboardingNudge =
          result.logs.isEmpty && OnboardingState.pendingScore != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final displayName =
        user?.userMetadata?['display_name'] as String? ?? 'there';
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
                          MaterialPageRoute(
                            builder: (_) => const ToolkitScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.bookmark_outline),
                        tooltip: 'My toolkit',
                      ),
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.settings_outlined),
                        tooltip: 'Settings',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_showOnboardingNudge) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppElevation.decoration(context),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Save the check-in from onboarding?',
                              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "We'll pre-fill it — takes one tap.",
                              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _dismissOnboardingNudge,
                        child: const Text('Not now'),
                      ),
                      FilledButton(
                        onPressed: () {
                          final score = OnboardingState.pendingScore!;
                          final tag = OnboardingState.pendingTag!;
                          OnboardingState.clearPending();
                          setState(() => _showOnboardingNudge = false);
                          _openMoodLog(initialScore: score, initialTag: tag);
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (!_loadingLogs) StreakBadge(logs: _logs),
              const SizedBox(height: 12),
              _loadingLogs
                  ? Container(
                      height: 280,
                      decoration: AppElevation.decoration(context),
                    )
                  : MoodTrendChart(logs: _logs),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _openMoodLog,
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
                  onLogMood: _openMoodLog,
                ),
                const SizedBox(height: 16),
                InsightsCard(userId: user.id),
                const SizedBox(height: 16),
                WeeklySummaryCard(userId: user.id),
                const SizedBox(height: 16),
                YearInPixels(userId: user.id),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: const CrisisFab(),
    );
  }
}
