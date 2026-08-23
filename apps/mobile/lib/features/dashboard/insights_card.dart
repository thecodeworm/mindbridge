import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/correlations.dart';
import '../../core/elevation.dart';
import '../../core/models.dart';
import '../mood/mood_log_service.dart';

class InsightsCard extends StatefulWidget {
  const InsightsCard({super.key, required this.userId});

  final String userId;

  @override
  State<InsightsCard> createState() => _InsightsCardState();
}

class _InsightsCardState extends State<InsightsCard> {
  final _service = MoodLogService(Supabase.instance.client);

  CorrelationsOutput? _correlations;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _service.getActivityTags(),
      _service.getLogsWithActivities(userId: widget.userId, days: 90),
    ]);

    if (!mounted) return;

    final tagsResult = results[0] as ({List<ActivityTag> tags, String? error});
    final logsResult =
        results[1] as ({List<({MoodLog log, List<ActivityTag> activities})> entries, String? error});

    final typed = logsResult.entries
        .map<LogWithActivities>((e) => (log: e.log, activities: e.activities))
        .toList();

    setState(() {
      _correlations = computeCorrelations(typed, tagsResult.tags);
      _loading = false;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activity insights', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'Based on the last 90 days (5+ entries per activity).',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_correlations!.positive.isEmpty && _correlations!.negative.isEmpty)
            Text(
              'Log more check-ins with activity tags to see patterns here.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            )
          else ...[
            if (_correlations!.positive.isNotEmpty) ...[
              Text('Mood boosters', style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ..._correlations!.positive.map((r) => _CorrelationRow(result: r, positive: true)),
            ],
            if (_correlations!.negative.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Mood dampeners', style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ..._correlations!.negative.map((r) => _CorrelationRow(result: r, positive: false)),
            ],
          ],
        ],
      ),
    );
  }
}

class _CorrelationRow extends StatelessWidget {
  const _CorrelationRow({required this.result, required this.positive});

  final CorrelationResult result;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final deltaStr = (result.delta > 0 ? '+' : '') + result.delta.toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text('${result.tag.emoji} ', style: const TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              result.tag.label,
              style: tt.bodySmall,
            ),
          ),
          Text(
            deltaStr,
            style: tt.bodySmall?.copyWith(
              color: positive ? Colors.green.shade700 : cs.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
