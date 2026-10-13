import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_events.dart';
import '../../core/app_exception.dart';
import '../../core/elevation.dart';
import '../../widgets/inline_notice.dart';
import '../../core/motion.dart';
import '../../widgets/crisis_fab.dart';
import '../../widgets/empty_state.dart';
import '../history/entry_detail_screen.dart';
import '../history/history_service.dart';
import '../mood/mood_log_screen.dart';

class ToolkitScreen extends StatefulWidget {
  const ToolkitScreen({super.key});

  @override
  State<ToolkitScreen> createState() => _ToolkitScreenState();
}

class _ToolkitScreenState extends State<ToolkitScreen> {
  final _service = HistoryService(Supabase.instance.client);
  List<CopingSuggestionDetail> _techniques = [];
  bool _loading = true;
  String? _error;

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
    try {
      final techniques = await _service.getSavedToolkit(userId: userId);
      if (!mounted) return;
      setState(() {
        _techniques = techniques;
        _error = null;
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

  Future<void> _unsave(CopingSuggestionDetail technique) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(
      () =>
          _techniques = _techniques.where((t) => t.id != technique.id).toList(),
    );

    await _service.updateSuggestionFeedback(
      moodLogId: technique.moodLogId,
      userId: userId,
      saved: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toolkit'),
        actions: const [HelpAction()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: [InlineNotice(message: _error!, onRetry: _load)],
            )
          : _techniques.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: EmptyState(
                  icon: Icons.bookmark_border,
                  headline: 'Keep what works',
                  copy:
                      'Save a technique after a check-in and it lands here, ready for the next hard moment.',
                  ctaLabel: 'Check in',
                  onCta: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MoodLogScreen()),
                    );
                    notifyMoodDataChanged();
                  },
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              itemCount: _techniques.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _TechniqueCard(
                technique: _techniques[i],
                onUnsave: () => _unsave(_techniques[i]),
                onOpenEntry: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EntryDetailScreen(
                        moodLogId: _techniques[i].moodLogId,
                      ),
                    ),
                  );
                  notifyMoodDataChanged();
                },
              ),
            ),
    );
  }
}

/// A saved technique; tapping the header expands its three steps so the
/// toolkit is usable in the moment, not just a list of names.
class _TechniqueCard extends StatefulWidget {
  const _TechniqueCard({
    required this.technique,
    required this.onUnsave,
    required this.onOpenEntry,
  });

  final CopingSuggestionDetail technique;
  final VoidCallback onUnsave;
  final VoidCallback onOpenEntry;

  @override
  State<_TechniqueCard> createState() => _TechniqueCardState();
}

class _TechniqueCardState extends State<_TechniqueCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final t = widget.technique;

    return Container(
      decoration: AppElevation.decoration(context),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.techniqueName, style: tt.titleLarge),
                          const SizedBox(height: 4),
                          Text(
                            t.description,
                            maxLines: _open ? null : 2,
                            overflow: _open ? null : TextOverflow.ellipsis,
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onUnsave,
                      icon: const Icon(Icons.bookmark),
                      tooltip: 'Remove from toolkit',
                      color: cs.primary,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: AppMotion.medium,
              curve: AppMotion.standard,
              alignment: Alignment.topCenter,
              child: !_open
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (i, step) in t.steps.take(3).indexed)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: cs.primary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${i + 1}',
                                      style: tt.labelMedium?.copyWith(
                                        color: cs.onPrimary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      step,
                                      style: tt.bodyMedium?.copyWith(
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: widget.onOpenEntry,
                              child: const Text('See the check-in'),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
