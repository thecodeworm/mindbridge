import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../core/elevation.dart';
import '../core/loading_tips.dart';
import '../core/motion.dart';
import 'notebook.dart';

/// A quiet "QUICK TIP" card shown under the breathing circle while the AI
/// suggestion loads. Starts on a random tip (or [startIndex]), then advances,
/// wrapping, every [interval]. Tips cross-fade over [fadeDuration]; with
/// reduced motion on (`MediaQuery.disableAnimations`) they swap instantly but
/// still rotate. The tip area keeps a fixed three-line min height so tips of
/// different lengths never make the layout jump.
/// Mirrors apps/web/src/components/LoadingTip.tsx.
class LoadingTip extends StatefulWidget {
  const LoadingTip({
    super.key,
    this.tips = kLoadingTips,
    this.interval = const Duration(seconds: 4),
    this.fadeDuration = const Duration(milliseconds: 300),
    this.startIndex,
    this.random,
  });

  final List<String> tips;
  final Duration interval;
  final Duration fadeDuration;

  /// First tip to show. Wins over [random]; tests pin it.
  final int? startIndex;

  /// Source for the random first tip when [startIndex] is null.
  final Random? random;

  @override
  State<LoadingTip> createState() => _LoadingTipState();
}

class _LoadingTipState extends State<LoadingTip> {
  static const _lines = 3;

  late int _index;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final count = widget.tips.length;
    _index = count == 0 ? 0 : (widget.startIndex ?? (widget.random ?? Random()).nextInt(count)) % count;
    if (count > 1) {
      _timer = Timer.periodic(widget.interval, (_) {
        if (!mounted) return;
        setState(() => _index = (_index + 1) % widget.tips.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tips.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.onSurface, height: 1.5);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final fontSize = style?.fontSize ?? 16;
    final minHeight = MediaQuery.textScalerOf(context).scale(fontSize * (style?.height ?? 1.5)) * _lines;
    final tip = widget.tips[_index];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: AppElevation.decoration(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SectionLabel('Quick tip'),
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: AnimatedSwitcher(
                  duration: reduceMotion ? Duration.zero : widget.fadeDuration,
                  switchInCurve: AppMotion.standardDecelerate,
                  child: Text(
                    tip,
                    key: ValueKey(_index),
                    textAlign: TextAlign.center,
                    style: style,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
