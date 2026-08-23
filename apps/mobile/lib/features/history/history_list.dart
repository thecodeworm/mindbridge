import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/elevation.dart';
import '../../core/mood_color.dart';
import '../../widgets/empty_state.dart';
import '../mood/mood_log_service.dart';
import 'entry_detail_screen.dart';
import 'history_service.dart';

const _kPageSize = 20;

class HistoryList extends StatefulWidget {
  const HistoryList({
    super.key,
    required this.userId,
    this.onEntryChanged,
    this.onLogMood,
  });

  final String userId;

  /// Called after returning from viewing an entry's detail screen, so a
  /// parent (the dashboard's mood trend chart) can refresh too — edits and
  /// deletes made there aren't otherwise visible outside this widget.
  final VoidCallback? onEntryChanged;

  /// Empty-state CTA — owned by the parent since starting a new mood log is
  /// a `features/mood` navigation this widget shouldn't import directly.
  final VoidCallback? onLogMood;

  @override
  State<HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<HistoryList> {
  final _service = HistoryService(Supabase.instance.client);

  final List<HistoryEntry> _entries = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.getHistory(
      userId: widget.userId,
      limit: _kPageSize + 1,
      offset: 0,
    );
    if (!mounted) return;
    setState(() {
      _entries
        ..clear()
        ..addAll(result.entries.take(_kPageSize));
      _error = result.error;
      _hasMore = result.entries.length > _kPageSize;
      _loading = false;
    });
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    final result = await _service.getHistory(
      userId: widget.userId,
      limit: _kPageSize + 1,
      offset: _entries.length,
    );
    if (!mounted) return;
    setState(() {
      _entries.addAll(result.entries.take(_kPageSize));
      _error = result.error;
      _hasMore = result.entries.length > _kPageSize;
      _loadingMore = false;
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('History', style: tt.titleMedium),
          const SizedBox(height: 12),
          if (_loading)
            ...List.generate(
              3,
              (_) => Container(
                height: 64,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          if (!_loading && _error != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: TextStyle(color: cs.error, fontSize: 14),
              ),
            ),
          if (!_loading && _error == null && _entries.isEmpty)
            EmptyState(
              icon: Icons.edit_note_outlined,
              headline: 'No entries yet',
              copy: 'Log your first mood to start tracking.',
              ctaLabel: widget.onLogMood != null ? 'Log a mood' : null,
              onCta: widget.onLogMood,
            ),
          if (!_loading)
            ..._entries.map(
              (entry) => MoodLogCard(
                entry: entry,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EntryDetailScreen(moodLogId: entry.id),
                    ),
                  );
                  if (!mounted) return;
                  await _load();
                  widget.onEntryChanged?.call();
                },
              ),
            ),
          if (!_loading && _hasMore && _entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: OutlinedButton(
                onPressed: _loadingMore ? null : _loadMore,
                child: Text(_loadingMore ? 'Loading…' : 'Load more'),
              ),
            ),
        ],
      ),
    );
  }
}

class MoodLogCard extends StatelessWidget {
  const MoodLogCard({super.key, required this.entry, required this.onTap});

  final HistoryEntry entry;
  final VoidCallback onTap;

  String _formatDate(DateTime d) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = moodColor(entry.moodScore);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${entry.moodScore}',
                    style: const TextStyle(
                      color: Color(0xFF1C1917),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _formatDate(entry.loggedAt),
                            style: tt.bodyMedium,
                          ),
                          const SizedBox(width: 6),
                          Text(moodTagInfo(entry.moodTag)?['emoji'] ?? ''),
                        ],
                      ),
                      Text(
                        entry.techniqueName ?? 'No suggestion saved',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
