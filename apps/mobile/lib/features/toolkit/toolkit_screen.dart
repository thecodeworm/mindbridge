import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/elevation.dart';
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
    _load();
  }

  Future<void> _load() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final result = await _service.getSavedToolkit(userId: userId);
    if (!mounted) return;
    setState(() {
      _techniques = result.techniques;
      _error = result.error;
      _loading = false;
    });
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My toolkit'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: cs.onSurface,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Text(_error!, style: TextStyle(color: cs.error)),
              )
            : _techniques.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: EmptyState(
                    icon: Icons.bookmark_border,
                    headline: 'Your toolkit is empty',
                    copy: 'Bookmark coping techniques you want to revisit.',
                    ctaLabel: 'Log a mood',
                    onCta: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MoodLogScreen()),
                    ),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _techniques.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final t = _techniques[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppElevation.decoration(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                t.techniqueName,
                                style: tt.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _unsave(t),
                              icon: const Icon(Icons.bookmark),
                              tooltip: 'Remove from toolkit',
                              color: cs.primary,
                              iconSize: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.description,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EntryDetailScreen(moodLogId: t.moodLogId),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('View entry →'),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: const CrisisFab(),
    );
  }
}
