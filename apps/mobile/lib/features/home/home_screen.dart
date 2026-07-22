import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/dashboard/mood_trend_chart.dart';
import '../auth/auth_service.dart';
import '../history/history_list.dart';
import '../mood/mood_log_screen.dart';
import '../mood/mood_log_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _moodLogService = MoodLogService(Supabase.instance.client);
  final _authService = AuthService(Supabase.instance.client);

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
    final result = await _moodLogService.getMoodLogsInRange(
      userId: userId,
      days: 30,
    );
    if (!mounted) return;
    setState(() {
      _logs = result.logs;
      _loadingLogs = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final displayName =
        user?.userMetadata?['display_name'] as String? ?? 'there';
    final cs = Theme.of(context).colorScheme;

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
                  OutlinedButton(
                    // Theme's default OutlinedButton minimumSize is
                    // Size.fromHeight(52) - i.e. infinite width - meant for
                    // buttons wrapped in Expanded/stretch (as everywhere else
                    // in the app). This button has no such wrapper, so it
                    // needs its own bounded minimumSize instead.
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                    onPressed: () => _authService.signOut(),
                    child: const Text('Log out'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
              if (user != null)
                HistoryList(key: ValueKey(_refreshTick), userId: user.id),
            ],
          ),
        ),
      ),
    );
  }
}
