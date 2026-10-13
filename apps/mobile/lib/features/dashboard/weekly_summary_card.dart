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

String _weekLabel() {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final start = DateTime.parse(_prevWeekStart());
  final end = start.add(const Duration(days: 6));
  return '${months[start.month - 1]} ${start.day} – ${months[end.month - 1]} ${end.day}';
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
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: AppElevation.decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Your week in review', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Text(_weekLabel(), style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_summary != null) ...[
            Text(_summary!.summary, style: tt.bodyLarge?.copyWith(height: 1.45)),
            if (_summary!.highlights.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._summary!.highlights.map(
                (h) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8, right: 10),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                        ),
                      ),
                      Expanded(
                        child: Text(h, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ] else ...[
            Text(
              'A short, kind reflection on last week: what stood out and what seemed to help.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 14),
            if (_error != null) ...[
              Text(_error!, style: tt.bodyMedium?.copyWith(color: cs.error)),
              const SizedBox(height: 10),
            ],
            OutlinedButton.icon(
              onPressed: _generating ? null : _generate,
              icon: _generating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome_outlined, size: 18),
              label: Text(_generating ? 'Writing your review…' : 'Write my week in review'),
            ),
          ],
        ],
      ),
    );
  }
}
