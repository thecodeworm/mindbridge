import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/mood_color.dart';
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
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
    final error = await _service.deleteEntry(
      moodLogId: widget.moodLogId,
      userId: userId,
    );
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
            if (!_loading && _error == null && _detail != null) ..._buildContent(cs, tt, _detail!),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 180,
            height: 24,
            decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
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

  List<Widget> _buildContent(ColorScheme cs, TextTheme tt, EntryDetail detail) {
    final moodLog = detail.moodLog;
    final color = moodColor(moodLog.moodScore);

    return [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline),
        ),
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
                    style: const TextStyle(color: Color(0xFF1C1917), fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${moodTagInfo(moodLog.moodTag)?['emoji'] ?? ''} ${moodTagInfo(moodLog.moodTag)?['label'] ?? moodLog.moodTag}',
                      style: tt.titleMedium,
                    ),
                    Text(_formatDate(moodLog.loggedAt), style: tt.bodySmall),
                  ],
                ),
              ],
            ),
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
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline),
        ),
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
