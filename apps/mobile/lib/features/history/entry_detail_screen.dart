import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_exception.dart';
import '../../core/crisis.dart';
import '../../core/elevation.dart';
import '../../core/mood_color.dart';
import '../../core/theme.dart';
import '../../widgets/crisis_fab.dart';
import '../../widgets/feedback_chip.dart';
import '../help/help_screen.dart';
import '../mood/mood_log_screen.dart';
import '../mood/mood_log_service.dart';
import 'history_service.dart';

class EntryDetailScreen extends StatefulWidget {
  const EntryDetailScreen({super.key, required this.moodLogId});

  final String moodLogId;

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  final _service = HistoryService(Supabase.instance.client);

  EntryDetail? _detail;
  bool _loading = true;
  String? _error;
  bool _deleting = false;

  bool? _helpful;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _service.getEntryDetail(
        moodLogId: widget.moodLogId,
        userId: userId,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _helpful = detail.copingSuggestion?.helpful;
        _saved = detail.copingSuggestion?.saved ?? false;
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

  String _formatDate(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<void> _setHelpful(bool? value) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || _detail == null) return;
    setState(() => _helpful = value);
    await _service.updateSuggestionFeedback(
      moodLogId: widget.moodLogId,
      userId: userId,
      helpful: value,
    );
  }

  Future<void> _toggleSaved() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || _detail == null) return;
    final next = !_saved;
    setState(() => _saved = next);
    await _service.updateSuggestionFeedback(
      moodLogId: widget.moodLogId,
      userId: userId,
      saved: next,
    );
  }

  Future<void> _edit() async {
    if (_detail == null) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MoodLogScreen(editing: _detail)),
    );
    if (result == true) _load();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: const Text(
          "This removes the mood log, journal entry, and coping suggestion. This can't be undone.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _deleting = true);
    final error = await _service.deleteEntry(moodLogId: widget.moodLogId, userId: userId);
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _deleting = false;
        _error = error;
      });
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entry'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: cs.onSurface,
        actions: [
          if (!_loading && _error == null && _detail != null)
            PopupMenuButton<String>(
              enabled: !_deleting,
              onSelected: (value) {
                if (value == 'edit') _edit();
                if (value == 'delete') _confirmDelete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: cs.error)),
                ),
              ],
            ),
          const HelpAction(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_loading) _buildSkeleton(cs),
            if (!_loading && _error != null) _buildError(cs),
            if (!_loading && _error == null && _detail != null)
              ..._buildContent(context, cs, tt, _detail!),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppElevation.decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 180,
            height: 24,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(8)),
      child: Text(_error!, style: TextStyle(color: cs.error, fontSize: 14)),
    );
  }

  List<Widget> _buildContent(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
    EntryDetail detail,
  ) {
    final moodLog = detail.moodLog;
    final color = moodColor(moodLog.moodScore);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final terraDark = isDark ? AppColors.dTerraDark : AppColors.terraDark;
    final terraTint = isDark ? AppColors.dTerraTint : AppColors.terraTint;
    final terra = isDark ? AppColors.dTerra : AppColors.terra;

    return [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: AppElevation.decoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    '${moodLog.moodScore}',
                    style: const TextStyle(
                      color: Color(0xFF1C1917),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${moodTagInfo(moodLog.moodTag)?['emoji'] ?? ''} '
                      '${moodTagInfo(moodLog.moodTag)?['label'] ?? moodLog.moodTag}',
                      style: tt.titleMedium,
                    ),
                    Text(_formatDate(moodLog.loggedAt), style: tt.bodySmall),
                  ],
                ),
              ],
            ),
            if (detail.activities.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: detail.activities.map((a) {
                  return Chip(
                    label: Text('${a.emoji} ${a.label}'),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                }).toList(),
              ),
            ],
            if (detail.journalEntry != null) ...[
              const SizedBox(height: 16),
              Divider(color: cs.outline),
              const SizedBox(height: 16),
              Text('Journal', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(detail.journalEntry!.body, style: tt.bodyMedium),
            ],
          ],
        ),
      ),
      if (detail.copingSuggestion != null &&
          shouldShowCrisisChip(
            crisisSignal: detail.copingSuggestion!.crisisSignal,
            moodScore: moodLog.moodScore,
          )) ...[
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HelpScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: terraTint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: terra.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.favorite_outline, size: 20, color: terraDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "You don't have to carry this alone. Tap for people you can reach right now.",
                    style: tt.bodyMedium?.copyWith(color: terraDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: AppElevation.decoration(context),
        child: detail.copingSuggestion != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(detail.copingSuggestion!.techniqueName, style: tt.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    detail.copingSuggestion!.description,
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  for (final (i, step) in detail.copingSuggestion!.steps.take(3).indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: moodColor(detail.moodLog.moodScore).withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: Text('${i + 1}', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(step, style: tt.bodyLarge?.copyWith(height: 1.4)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FeedbackChip(
                        icon: Icons.thumb_up_outlined,
                        activeIcon: Icons.thumb_up,
                        label: 'Helpful',
                        active: _helpful == true,
                        onTap: () => _setHelpful(_helpful == true ? null : true),
                      ),
                      FeedbackChip(
                        icon: Icons.thumb_down_outlined,
                        activeIcon: Icons.thumb_down,
                        label: 'Not for me',
                        active: _helpful == false,
                        onTap: () => _setHelpful(_helpful == false ? null : false),
                      ),
                      FeedbackChip(
                        icon: Icons.bookmark_outline,
                        activeIcon: Icons.bookmark,
                        label: _saved ? 'In your toolkit' : 'Save to toolkit',
                        active: _saved,
                        onTap: _toggleSaved,
                      ),
                    ],
                  ),
                ],
              )
            : Text(
                'No coping suggestion was saved for this entry.',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
      ),
    ];
  }
}
