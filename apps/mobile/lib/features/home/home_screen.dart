import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_events.dart';
import '../../core/elevation.dart';
import '../../core/mood_color.dart';
import '../../core/onboarding_state.dart';
import '../../features/dashboard/streak_badge.dart';
import '../../widgets/crisis_fab.dart';
import '../history/entry_detail_screen.dart';
import '../history/history_list.dart';
import '../history/history_service.dart';
import '../mood/mood_log_screen.dart';
import '../mood/mood_log_service.dart';
import '../settings/settings_screen.dart';
import '../shell/main_shell.dart';

/// "Today" tab: one clear job (check in), then a glance at the week and the
/// last few entries. Deeper analytics live on the Insights tab.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _moodLogService = MoodLogService(Supabase.instance.client);
  final _historyService = HistoryService(Supabase.instance.client);

  List<MoodLog> _logs = [];
  List<HistoryEntry> _recent = [];
  bool _loading = true;
  bool _showOnboardingNudge = false;

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

  Future<void> _openMoodLog({double? initialScore, String? initialTag}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MoodLogScreen(initialScore: initialScore, initialTag: initialTag),
      ),
    );
    notifyMoodDataChanged();
  }

  Future<void> _openEntry(String id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EntryDetailScreen(moodLogId: id)),
    );
    notifyMoodDataChanged();
  }

  void _dismissOnboardingNudge() {
    OnboardingState.clearPending();
    setState(() => _showOnboardingNudge = false);
  }

  Future<void> _load() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    // Errors are swallowed here by design: Today degrades to its first-run
    // state rather than showing an error card on the app's front door.
    var logs = <MoodLog>[];
    var recent = <HistoryEntry>[];
    try {
      final results = await Future.wait([
        _moodLogService.getMoodLogsInRange(userId: userId, days: 30),
        _historyService.getHistory(userId: userId, limit: 3),
      ]);
      logs = results[0] as List<MoodLog>;
      recent = results[1] as List<HistoryEntry>;
    } catch (_) {
      // ignored, see above
    }
    if (!mounted) return;
    setState(() {
      _logs = logs;
      _recent = recent;
      _loading = false;
      _showOnboardingNudge = logs.isEmpty && OnboardingState.pendingScore != null;
    });
  }

  MoodLog? get _todaysLatest {
    final now = DateTime.now();
    MoodLog? latest;
    for (final l in _logs) {
      final d = l.loggedAt.toLocal();
      if (d.year == now.year && d.month == now.month && d.day == now.day) {
        if (latest == null || l.loggedAt.isAfter(latest.loggedAt)) latest = l;
      }
    }
    return latest;
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final rawName = user?.userMetadata?['display_name'] as String?;
    final firstName = (rawName == null || rawName.trim().isEmpty)
        ? null
        : rawName.trim().split(' ').first;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // ── Header ───────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatToday(DateTime.now()),
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                const HelpChip(),
                const SizedBox(width: 4),
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
            const SizedBox(height: 4),
            Text(
              firstName == null ? _greeting() : '${_greeting()}, $firstName',
              style: tt.headlineMedium?.copyWith(height: 1.15),
            ),
            const SizedBox(height: 24),

            if (_showOnboardingNudge) ...[
              _OnboardingNudge(
                onDismiss: _dismissOnboardingNudge,
                onSave: () {
                  final score = OnboardingState.pendingScore!;
                  final tag = OnboardingState.pendingTag!;
                  OnboardingState.clearPending();
                  setState(() => _showOnboardingNudge = false);
                  _openMoodLog(initialScore: score, initialTag: tag);
                },
              ),
              const SizedBox(height: 16),
            ],

            // ── Check-in hero ────────────────────────────────────────
            if (_loading)
              Container(height: 212, decoration: AppElevation.decoration(context))
            else if (_todaysLatest case final today?)
              _CheckedInCard(
                log: today,
                techniqueName: _recent.isNotEmpty && _recent.first.id == today.id
                    ? _recent.first.techniqueName
                    : null,
                onOpen: () => _openEntry(today.id),
                onCheckInAgain: _openMoodLog,
              )
            else
              _CheckInPrompt(
                onPick: (score) => _openMoodLog(initialScore: score),
                onCheckIn: _openMoodLog,
              ),
            const SizedBox(height: 28),

            // ── This week ────────────────────────────────────────────
            if (!_loading) ...[
              _SectionHeader(title: 'This week'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                decoration: AppElevation.decoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _WeekStrip(logs: _logs),
                    if (_logs.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 14),
                      StreakBadge(logs: _logs),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],

            // ── Recent entries ───────────────────────────────────────
            if (!_loading && _recent.isNotEmpty) ...[
              _SectionHeader(
                title: 'Recent',
                actionLabel: 'See all',
                onAction: () => MainShell.goToTab(context, MainShell.journal),
              ),
              const SizedBox(height: 12),
              for (final entry in _recent)
                MoodLogCard(entry: entry, onTap: () => _openEntry(entry.id)),
            ],
          ],
        ),
      ),
    );
  }
}

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 5) return 'Still up';
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  if (h < 22) return 'Good evening';
  return 'Winding down';
}

const _kWeekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _kMonths = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
  'September', 'October', 'November', 'December',
];

String _formatToday(DateTime d) => '${_kWeekdays[d.weekday - 1]}, ${_kMonths[d.month - 1]} ${d.day}';

String _formatTime(BuildContext context, DateTime d) =>
    TimeOfDay.fromDateTime(d.toLocal()).format(context);

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(48, 36),
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

/// Not-yet-checked-in state. Five mood-temperature dots double as a
/// one-tap shortcut into the log screen with the score pre-set.
class _CheckInPrompt extends StatelessWidget {
  const _CheckInPrompt({required this.onPick, required this.onCheckIn});

  final ValueChanged<double> onPick;
  final VoidCallback onCheckIn;

  static const _scores = [2.0, 4.0, 6.0, 8.0, 10.0];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: AppElevation.decoration(context, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('How are you, really?', style: tt.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Tap the closest feeling. You\'ll get one small thing to try, right away.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final s in _scores)
                _MoodDot(score: s, onTap: () => onPick(s)),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCheckIn,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Check in'),
          ),
        ],
      ),
    );
  }
}

class _MoodDot extends StatelessWidget {
  const _MoodDot({required this.score, required this.onTap});

  final double score;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final color = moodColor(score);
    return Semantics(
      button: true,
      label: 'Check in feeling ${moodWord(score)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                moodWord(score),
                style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Already-checked-in state: today's mood, its tag, and the technique the
/// user got, with a quieter path to log again.
class _CheckedInCard extends StatelessWidget {
  const _CheckedInCard({
    required this.log,
    required this.techniqueName,
    required this.onOpen,
    required this.onCheckInAgain,
  });

  final MoodLog log;
  final String? techniqueName;
  final VoidCallback onOpen;
  final VoidCallback onCheckInAgain;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = moodColor(log.moodScore);
    final tag = moodTagInfo(log.moodTag);

    return Container(
      decoration: AppElevation.decoration(context, radius: 20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withValues(alpha: 0.55), color]),
            ),
          ),
          InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
              child: Row(
                children: [
                  _ScoreBubble(score: log.moodScore, size: 56),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You checked in',
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tag != null ? '${tag['label']} ${tag['emoji']}' : moodWord(log.moodScore),
                          style: tt.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTime(context, log.loggedAt),
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
          if (techniqueName != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.self_improvement, size: 20, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        techniqueName!,
                        style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onCheckInAgain,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Check in again'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBubble extends StatelessWidget {
  const _ScoreBubble({required this.score, required this.size});

  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: moodColor(score)),
      child: Text(
        '$score',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF1C1917),
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
      ),
    );
  }
}

/// The last seven days as mood-colored dots, today on the right. Days with
/// several check-ins show the latest one.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.logs});

  final List<MoodLog> logs;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final byDay = <DateTime, MoodLog>{};
    for (final l in logs) {
      final d = l.loggedAt.toLocal();
      final key = DateTime(d.year, d.month, d.day);
      final existing = byDay[key];
      if (existing == null || l.loggedAt.isAfter(existing.loggedAt)) byDay[key] = l;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (int i = 6; i >= 0; i--)
          Builder(builder: (context) {
            final day = today.subtract(Duration(days: i));
            final log = byDay[day];
            final isToday = i == 0;
            return Column(
              children: [
                Text(
                  'MTWTFSS'[day.weekday - 1],
                  style: tt.labelMedium?.copyWith(
                    color: isToday ? cs.onSurface : cs.onSurfaceVariant,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: log != null ? moodColor(log.moodScore) : Colors.transparent,
                    border: log == null
                        ? Border.all(
                            color: isToday ? cs.primary : cs.outline,
                            width: isToday ? 2 : 1.5,
                          )
                        : null,
                  ),
                  child: log != null
                      ? Text(
                          '${log.moodScore}',
                          style: tt.labelLarge?.copyWith(
                            color: const Color(0xFF1C1917),
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        )
                      : null,
                ),
              ],
            );
          }),
      ],
    );
  }
}

class _OnboardingNudge extends StatelessWidget {
  const _OnboardingNudge({required this.onDismiss, required this.onSave});

  final VoidCallback onDismiss;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      decoration: AppElevation.decoration(context, color: cs.primaryContainer),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Save the check-in from onboarding?',
            style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            "We'll pre-fill it. It takes one tap.",
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onDismiss, child: const Text('Not now')),
              TextButton(onPressed: onSave, child: const Text('Save it')),
            ],
          ),
        ],
      ),
    );
  }
}
