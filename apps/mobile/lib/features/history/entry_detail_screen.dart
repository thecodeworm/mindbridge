import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/crisis.dart';
import '../../core/elevation.dart';
import '../../core/mood_color.dart';
import '../../core/theme.dart';
import '../../widgets/crisis_fab.dart';
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
    final result = await _service.getEntryDetail(
      moodLogId: widget.moodLogId,
      userId: userId,
    );
    if (!mounted) return;
    setState(() {
      _detail = result.detail;
      _helpful = result.detail?.copingSuggestion?.helpful;
      _saved = result.detail?.copingSuggestion?.saved ?? false;
      _error = result.error;
      _loading = false;
    });
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
        title: const Text('Entry detail'),
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
      floatingActionButton: const CrisisFab(),
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
              border: Border.all(color: terra),
            ),
            child: Text(
              "If you're in crisis, you're not alone — tap for crisis resources.",
              style: TextStyle(fontSize: 13, color: terraDark),
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
                  Text(detail.copingSuggestion!.techniqueName, style: tt.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    detail.copingSuggestion!.description,
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  ...detail.copingSuggestion!.steps.take(3).toList().asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${entry.key + 1}. ', style: tt.bodyMedium),
                              Expanded(child: Text(entry.value, style: tt.bodyMedium)),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: 16),
                  // Feedback row
                  Row(
                    children: [
                      Text(
                        'Helpful?',
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(width: 8),
                      _FeedbackButton(
                        icon: '👍',
                        active: _helpful == true,
                        onTap: () => _setHelpful(_helpful == true ? null : true),
                      ),
                      const SizedBox(width: 4),
                      _FeedbackButton(
                        icon: '👎',
                        active: _helpful == false,
                        onTap: () => _setHelpful(_helpful == false ? null : false),
                      ),
                      const Spacer(),
                      _FeedbackButton(
                        icon: _saved ? '🔖' : '🏷️',
                        active: _saved,
                        onTap: _toggleSaved,
                        tooltip: _saved ? 'Remove from toolkit' : 'Save to toolkit',
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

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({
    required this.icon,
    required this.active,
    required this.onTap,
    this.tooltip,
  });

  final String icon;
  final bool active;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? cs.primaryContainer : Colors.transparent,
            border: Border.all(color: active ? cs.primary : cs.outline),
          ),
          alignment: Alignment.center,
          child: Text(icon, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
