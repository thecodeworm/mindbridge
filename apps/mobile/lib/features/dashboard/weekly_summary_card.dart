import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/elevation.dart';
import '../../core/models.dart';

String _prevWeekStart() {
  final now = DateTime.now().toLocal();
  final daysToLastMonday = (now.weekday - 1) + 7;
  final lastMonday = DateTime(now.year, now.month, now.day - daysToLastMonday);
  return '${lastMonday.year}-${lastMonday.month.toString().padLeft(2, '0')}-${lastMonday.day.toString().padLeft(2, '0')}';
}

class WeeklySummaryCard extends StatefulWidget {
  const WeeklySummaryCard({super.key, required this.userId});

  final String userId;

  @override
  State<WeeklySummaryCard> createState() => _WeeklySummaryCardState();
}

class _WeeklySummaryCardState extends State<WeeklySummaryCard> {
  final _client = Supabase.instance.client;

  WeeklySummary? _summary;
  bool _loading = true;
  bool _generating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCached();
  }

  Future<void> _loadCached() async {
    final weekStart = _prevWeekStart();
    try {
      final data = await _client
          .from('weekly_summaries')
          .select('id, user_id, week_start, summary, highlights, generated_at')
          .eq('user_id', widget.userId)
          .eq('week_start', weekStart)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        _summary = data != null ? WeeklySummary.fromJson(data) : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _error = null;
    });

    try {
      final weekStart = _prevWeekStart();
      final response = await _client.functions.invoke(
        'generate-weekly-summary',
        body: {'user_id': widget.userId, 'week_start': weekStart},
      );
      if (!mounted) return;
      if (response.status != 200) {
        throw Exception('Status ${response.status}');
      }
      final data = response.data as Map<String, dynamic>?;
      if (data == null) throw Exception('No data');

      // Re-fetch from DB to get canonical row with id.
      await _loadCached();
      if (_summary == null && data['summary'] != null) {
        setState(() {
          _summary = WeeklySummary(
            id: '',
            userId: widget.userId,
            weekStart: DateTime.parse(weekStart),
            summary: data['summary'] as String? ?? '',
            highlights:
                ((data['highlights'] as List<dynamic>?) ?? []).map((e) => e as String).toList(),
            generatedAt: DateTime.now(),
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not generate summary. Try again later.');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppElevation.decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last week\'s summary', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_summary != null) ...[
            Text(_summary!.summary, style: tt.bodySmall),
            if (_summary!.highlights.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._summary!.highlights.map(
                (h) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      Expanded(
                        child: Text(h, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ] else ...[
            Text(
              'Get a gentle reflection on last week\'s mood patterns.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            if (_error != null) ...[
              Text(_error!, style: tt.bodySmall?.copyWith(color: cs.error)),
              const SizedBox(height: 8),
            ],
            FilledButton(
              onPressed: _generating ? null : _generate,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              child: Text(_generating ? 'Generating…' : 'Generate summary'),
            ),
          ],
        ],
      ),
    );
  }
}
