import 'package:flutter/material.dart';
import '../core/motion.dart';

/// MindBridge's signature breathing-circle: a soft glow that expands and
/// contracts on a real breath cadence (default ~4s in, ~4s out), reused as
/// the AI-suggestion "thinking" state, an optional pre-journal calming beat,
/// and on the crisis-resources screen. Pass [color] for a single fixed tone,
/// or [colors] to slowly cycle through a palette (e.g. the full mood ramp) —
/// the color cycle runs on its own independent, slower loop so a color
/// change never reads as "one color per breath."
class BreathingCircle extends StatefulWidget {
  const BreathingCircle({
    super.key,
    this.color,
    this.colors,
    this.size = 96,
    this.cycleDuration = const Duration(seconds: 4),
  }) : assert(color != null || colors != null, 'Provide color or colors');

  final Color? color;
  final List<Color>? colors;
  final double size;

  /// Duration of one inhale OR exhale leg — a full breath is twice this.
  final Duration cycleDuration;

  @override
  State<BreathingCircle> createState() => _BreathingCircleState();
}

class _BreathingCircleState extends State<BreathingCircle>
    with TickerProviderStateMixin {
  late final AnimationController _breathController = AnimationController(
    duration: widget.cycleDuration,
    vsync: this,
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween<double>(begin: 0.75, end: 1.0)
      .animate(
        CurvedAnimation(
          parent: _breathController,
          curve: AppMotion.easeInOutCubic,
        ),
      );

  AnimationController? _colorController;

  @override
  void initState() {
    super.initState();
    final colors = widget.colors;
    if (colors != null && colors.length > 1) {
      _colorController = AnimationController(
        duration: widget.cycleDuration * 2 * colors.length,
        vsync: this,
      )..repeat();
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    _colorController?.dispose();
    super.dispose();
  }

  Color _currentColor() {
    final colors = widget.colors;
    if (colors == null || colors.isEmpty) return widget.color!;
    final controller = _colorController;
    if (colors.length == 1 || controller == null) return colors.first;
    final t = controller.value * colors.length;
    final i = t.floor() % colors.length;
    final next = (i + 1) % colors.length;
    return Color.lerp(colors[i], colors[next], t - t.floor())!;
  }

  @override
  Widget build(BuildContext context) {
    final colorController = _colorController;
    final listenable = colorController == null
        ? _breathController
        : Listenable.merge([_breathController, colorController]);

    return AnimatedBuilder(
      animation: listenable,
      builder: (context, _) {
        final color = _currentColor();
        return Transform.scale(
          scale: _scale.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: 0.35),
                  color.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
