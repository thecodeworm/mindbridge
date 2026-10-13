import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/correlations.dart';
import '../../core/elevation.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
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
    // Errors are swallowed here by design — this card degrades to "not
    // enough data yet" rather than showing an error state.
    var tags = <ActivityTag>[];
    var logsWithActivities = <({MoodLog log, List<ActivityTag> activities})>[];
    try {
      final results = await Future.wait([
        _service.getActivityTags(),
        _service.getLogsWithActivities(userId: widget.userId, days: 90),
      ]);
      tags = results[0] as List<ActivityTag>;
      logsWithActivities =
          results[1] as List<({MoodLog log, List<ActivityTag> activities})>;
    } catch (_) {
      // ignored, see above
    }

    if (!mounted) return;

    final typed = logsWithActivities
        .map<LogWithActivities>((e) => (log: e.log, activities: e.activities))
        .toList();

    setState(() {
      _correlations = computeCorrelations(typed, tags);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: AppElevation.decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What lifts you', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'Activities tagged on 5+ check-ins in the last 90 days, compared with your average. Patterns, not causes.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_correlations!.positive.isEmpty && _correlations!.negative.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_offer_outlined, size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tag what you were doing when you check in. After about a week, patterns show up here.',
                      style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            if (_correlations!.positive.isNotEmpty) ...[
              Text('Tends to lift your mood', style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 6),
              ..._correlations!.positive.map((r) => _CorrelationRow(result: r, positive: true)),
            ],
            if (_correlations!.negative.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Tends to weigh on you', style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Sage for lifts, slate (the low end of the mood ramp) for dips: never
    // red/green judgement, per CLAUDE.md.
    final tone = positive
        ? (dark ? AppColors.dSuccess : AppColors.success)
        : const Color(0xFF7C8BA8);
    final deltaStr = (result.delta > 0 ? '+' : '') + result.delta.toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('${result.tag.emoji}  ', style: const TextStyle(fontSize: 16)),
          Expanded(
            child: Text(result.tag.label, style: tt.bodyMedium),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              deltaStr,
              style: tt.labelLarge?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
