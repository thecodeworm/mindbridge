import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_events.dart';
import '../../core/app_exception.dart';
import '../../core/elevation.dart';
import '../../core/mood_color.dart';
import '../../widgets/empty_state.dart';
import '../../core/theme.dart';
import '../../widgets/inline_notice.dart';
import '../../widgets/notebook.dart';
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
    moodDataVersion.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    moodDataVersion.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    // Keep showing current entries during a background refresh; only the
    // very first load gets the skeleton.
    if (_entries.isEmpty) setState(() => _loading = true);
    try {
      final entries = await _service.getHistory(
        userId: widget.userId,
        limit: _kPageSize + 1,
        offset: 0,
      );
      if (!mounted) return;
      setState(() {
        _entries
          ..clear()
          ..addAll(entries.take(_kPageSize));
        _error = null;
        _hasMore = entries.length > _kPageSize;
        _loading = false;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final entries = await _service.getHistory(
        userId: widget.userId,
        limit: _kPageSize + 1,
        offset: _entries.length,
      );
      if (!mounted) return;
      setState(() {
        _entries.addAll(entries.take(_kPageSize));
        _error = null;
        _hasMore = entries.length > _kPageSize;
        _loadingMore = false;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    final children = <Widget>[];
    String? lastMonth;
    for (final entry in _entries) {
      final local = entry.loggedAt.toLocal();
      final month = '${_kMonthNames[local.month - 1]} ${local.year}';
      if (month != lastMonth) {
        children.add(Padding(
          padding: EdgeInsets.only(top: lastMonth == null ? 0 : 20, bottom: 10, left: 4),
          child: SectionLabel(month),
        ));
        lastMonth = month;
      }
      children.add(MoodLogCard(
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
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loading)
          ...List.generate(
            4,
            (_) => Container(
              height: 72,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: AppElevation.decoration(context),
            ),
          ),
        if (!_loading && _error != null)
          InlineNotice(message: _error!, onRetry: _load),
        if (!_loading && _error == null && _entries.isEmpty)
          EmptyState(
            icon: Icons.menu_book_outlined,
            headline: 'Your journal starts here',
            copy: 'Every check-in lands here, with the technique you got.',
            ctaLabel: widget.onLogMood != null ? 'Check in' : null,
            onCta: widget.onLogMood,
          ),
        if (!_loading) ...children,
        if (!_loading && _hasMore && _entries.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton(
              onPressed: _loadingMore ? null : _loadMore,
              child: Text(_loadingMore ? 'Loading…' : 'Show older entries'),
            ),
          ),
      ],
    );
  }
}

const _kMonthNames = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
  'September', 'October', 'November', 'December',
];

class MoodLogCard extends StatelessWidget {
  const MoodLogCard({super.key, required this.entry, required this.onTap});

  final HistoryEntry entry;
  final VoidCallback onTap;

  String _formatDate(BuildContext context, DateTime d) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final local = d.toLocal();
    final time = TimeOfDay.fromDateTime(local).format(context);
    return '${weekdays[local.weekday - 1]}, ${months[local.month - 1]} ${local.day} · $time';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = moodColor(entry.moodScore);
    final tag = moodTagInfo(entry.moodTag);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: AppElevation.decoration(context),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child: Text(
                      '${entry.moodScore}',
                      style: tt.titleMedium?.copyWith(
                        color: AppColors.onMood,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tag != null ? '${tag['label']} ${tag['emoji']}' : moodWord(entry.moodScore),
                          style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.techniqueName ?? _formatDate(context, entry.loggedAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        if (entry.techniqueName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(context, entry.loggedAt),
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
