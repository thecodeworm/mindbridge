import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/mood_color.dart';
import '../mood/mood_log_service.dart';

class MoodTrendChart extends StatefulWidget {
  const MoodTrendChart({super.key, required this.logs});

  final List<MoodLog> logs;

  @override
  State<MoodTrendChart> createState() => _MoodTrendChartState();
}

class _MoodTrendChartState extends State<MoodTrendChart> {
  int _rangeDays = 7;

  List<MoodLog> get _data {
    if (_rangeDays == 30) return widget.logs;
    final since = DateTime.now().subtract(const Duration(days: 7));
    return widget.logs.where((l) => l.loggedAt.isAfter(since)).toList();
  }

  String _tickLabel(DateTime d) {
    return _rangeDays == 7
        ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1]
        : '${d.month}/${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final data = _data;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mood trend', style: tt.titleMedium),
              _RangeToggle(
                value: _rangeDays,
                onChanged: (v) => setState(() => _rangeDays = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (data.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No entries in this range yet — log a mood to start your trend.',
                  textAlign: TextAlign.center,
                  style: tt.bodySmall,
                ),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: 1,
                  maxY: 10,
                  gridData: FlGridData(
                    horizontalInterval: 2,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(color: cs.outline, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 3,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) => Text(
                          value.round().toString(),
                          style: tt.bodySmall,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: data.length > 8 ? (data.length / 4).ceilToDouble() : 1,
                        getTitlesWidget: (value, meta) {
                          final i = value.round();
                          if (i < 0 || i >= data.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(_tickLabel(data[i].loggedAt), style: tt.bodySmall),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => cs.surface,
                      tooltipBorder: BorderSide(color: cs.outline),
                      getTooltipItems: (spots) => spots.map((s) {
                        final log = data[s.x.round()];
                        final info = moodTagInfo(log.moodTag);
                        final tagLabel = info != null
                            ? '${info['emoji']} ${info['label']}'
                            : log.moodTag;
                        return LineTooltipItem(
                          '${log.moodScore} · $tagLabel',
                          tt.bodySmall!.copyWith(fontWeight: FontWeight.w600),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (int i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i].moodScore.toDouble()),
                      ],
                      isCurved: false,
                      color: cs.primary,
                      barWidth: 2,
                      dotData: FlDotData(
                        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                          radius: 4,
                          color: moodColor(spot.y),
                          strokeColor: cs.surface,
                          strokeWidth: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RangeToggle extends StatelessWidget {
  const _RangeToggle({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget button(int days) {
      final selected = value == days;
      return GestureDetector(
        onTap: () => onChanged(days),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${days}d',
            style: TextStyle(
              color: selected ? cs.onPrimary : cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outline),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [button(7), button(30)]),
    );
  }
}
