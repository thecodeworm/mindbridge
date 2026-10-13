import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/elevation.dart';
import '../../core/mood_color.dart';
import '../../core/motion.dart';
import '../mood/mood_log_service.dart';

class MoodTrendChart extends StatefulWidget {
  const MoodTrendChart({super.key, required this.logs});

  final List<MoodLog> logs;

  @override
  State<MoodTrendChart> createState() => _MoodTrendChartState();
}

class _MoodTrendChartState extends State<MoodTrendChart>
    with SingleTickerProviderStateMixin {
  int _rangeDays = 7;

  late final AnimationController _drawController = AnimationController(
    duration: AppMotion.extraLong,
    vsync: this,
  );
  late final Animation<double> _drawAnim = CurvedAnimation(
    parent: _drawController,
    curve: AppMotion.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    _drawController.forward();
  }

  @override
  void dispose() {
    _drawController.dispose();
    super.dispose();
  }

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
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      decoration: AppElevation.decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mood trend', style: tt.titleLarge),
              _RangeToggle(
                value: _rangeDays,
                onChanged: (v) {
                  setState(() => _rangeDays = v);
                  _drawController.forward(from: 0);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (data.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No check-ins in this range yet. Log one to start your trend.',
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final chart = _buildChart(context, cs, tt, data);
                  return ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedBuilder(
                        animation: _drawAnim,
                        builder: (context, child) => SizedBox(
                          width: constraints.maxWidth * _drawAnim.value,
                          child: child,
                        ),
                        child: SizedBox(
                          width: constraints.maxWidth,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10, right: 14),
                            child: chart,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
    List<MoodLog> data,
  ) {
    return LineChart(
      LineChartData(
        minY: 1,
        maxY: 10,
        minX: -0.25,
        maxX: data.length - 0.75,
        gridData: FlGridData(
          horizontalInterval: 1,
          drawVerticalLine: false,
          checkToShowHorizontalLine: (v) => _kAxisMarks.contains(v.round()) && (v - v.round()).abs() < 0.01,
          getDrawingHorizontalLine: (v) => FlLine(
            color: cs.outline,
            strokeWidth: 1,
            dashArray: v.round() == 1 ? null : [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final v = value.round();
                if (!_kAxisMarks.contains(v) || (value - v).abs() > 0.01) {
                  return const SizedBox.shrink();
                }
                return Text(
                  '$v',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: data.length > 8 ? (data.length / 4).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= data.length || (value - i).abs() > 0.01) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _tickLabel(data[i].loggedAt),
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
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
              for (int i = 0; i < data.length; i++)
                FlSpot(i.toDouble(), data[i].moodScore.toDouble()),
            ],
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            color: cs.onSurface,
            barWidth: 2.5,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  cs.primary.withValues(alpha: 0.12),
                  cs.primary.withValues(alpha: 0),
                ],
              ),
            ),
            dotData: FlDotData(
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4.5,
                color: moodColor(spot.y),
                strokeColor: cs.surface,
                strokeWidth: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Y-axis marks: bottom, middle and top of the 1–10 scale only.
const _kAxisMarks = {1, 5, 10};

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? cs.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? const [BoxShadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 3)]
                : null,
          ),
          child: Text(
            '${days}d',
            style: TextStyle(
              color: selected ? cs.onSurface : cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [button(7), button(30)],
      ),
    );
  }
}
