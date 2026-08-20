import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import '../core/elevation.dart';
import '../core/mood_color.dart';
import '../core/motion.dart';

/// MindBridge's felt mood-entry slider, per
/// docs/research/00-design-direction.md §5: thumb scales up on drag start
/// (wobbly spring settle on release), track fill continuously interpolates
/// through the mood-temperature ramp, a numeral bubble floats above the
/// thumb while dragging, light haptic on each integer step (mobile only).
///
/// A custom drag surface rather than a themed [Slider] — the thumb-scale +
/// floating-label combination isn't expressible through [SliderThemeData].
class FeltMoodSlider extends StatefulWidget {
  const FeltMoodSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 10,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;

  @override
  State<FeltMoodSlider> createState() => _FeltMoodSliderState();
}

class _FeltMoodSliderState extends State<FeltMoodSlider>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController = AnimationController(
    vsync: this,
    upperBound: 1,
  );

  bool _dragging = false;
  int? _lastHapticStep;

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  double get _fraction =>
      ((widget.value - widget.min) / (widget.max - widget.min)).clamp(0, 1);

  void _updateFromLocalX(double dx, double width) {
    final fraction = (dx / width).clamp(0.0, 1.0);
    final raw = widget.min + fraction * (widget.max - widget.min);
    widget.onChanged(raw);

    final step = raw.round();
    if (!kIsWeb && step != _lastHapticStep) {
      _lastHapticStep = step;
      HapticFeedback.selectionClick();
    }
  }

  void _onDragStart() {
    setState(() => _dragging = true);
    _lastHapticStep = widget.value.round();
    _scaleController.animateTo(1, duration: AppMotion.short, curve: AppMotion.standard);
  }

  void _onDragEnd() {
    setState(() => _dragging = false);
    // Impulse spring: released thumb overshoots back toward rest (0 = base
    // scale) — same mechanism as streak_badge.dart's milestone pop.
    _scaleController.animateWith(
      SpringSimulation(AppMotion.springWobbly, _scaleController.value, 0, 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = moodColor(widget.value);
    const trackHeight = 10.0;
    const thumbDiameter = 28.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final thumbCenter = _fraction * width;

        return SizedBox(
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: (64 - trackHeight) / 2,
                child: Container(
                  height: trackHeight,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _fraction,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (details) {
                  _onDragStart();
                  _updateFromLocalX(details.localPosition.dx, width);
                },
                onHorizontalDragUpdate: (details) =>
                    _updateFromLocalX(details.localPosition.dx, width),
                onHorizontalDragEnd: (_) => _onDragEnd(),
                onHorizontalDragCancel: _onDragEnd,
                onTapDown: (details) {
                  _onDragStart();
                  _updateFromLocalX(details.localPosition.dx, width);
                },
                onTapUp: (_) => _onDragEnd(),
                child: SizedBox(width: width, height: 64),
              ),
              AnimatedBuilder(
                animation: _scaleController,
                builder: (context, child) {
                  final scale = 1.0 + _scaleController.value * 0.16;
                  return Positioned(
                    left: thumbCenter - thumbDiameter / 2,
                    top: (64 - thumbDiameter) / 2,
                    child: IgnorePointer(
                      child: Transform.scale(scale: scale, child: child),
                    ),
                  );
                },
                child: Container(
                  width: thumbDiameter,
                  height: thumbDiameter,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.surface, width: 3),
                    boxShadow: AppElevation.shadows(
                      ElevationLevel.elevated,
                      Theme.of(context).brightness,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: (thumbCenter - 20).clamp(0.0, width - 40),
                top: 0,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _dragging ? 1 : 0,
                    duration: AppMotion.micro,
                    child: Container(
                      width: 40,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: Text(
                        '${widget.value.round()}',
                        style: tt.labelLarge?.copyWith(
                          color: cs.surface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
