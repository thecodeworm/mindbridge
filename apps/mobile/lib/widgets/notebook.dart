import 'package:flutter/material.dart';
import '../core/theme.dart';

/// The Notebook direction's signature: a highlighter-pen band behind the
/// lower part of each line of text. Works across line wraps because the
/// band is a vertically repeating gradient sized to one line.
///
/// In dark mode the band covers the full word with dark text
/// ([AppColors.onMood]) so it stays readable on the light marker colors.
class Highlight extends StatelessWidget {
  const Highlight(this.text, {super.key, required this.color, required this.style, this.textAlign});

  final String text;
  final Color color;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    // Light: a low band under normal ink. Dark: the marker covers the whole
    // word with dark text, so no part of a letter is dark-on-dark.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final top = dark ? 0.08 : 0.52;
    final fontSize = base.fontSize ?? 16;
    final lineHeight = fontSize * (base.height ?? 1.1);
    final band = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.transparent, color, color, Colors.transparent],
        stops: [0, top, top, 0.92, 0.92],
        tileMode: TileMode.repeated,
      ).createShader(Rect.fromLTWH(0, 0, 1, lineHeight));
    return Text.rich(
      TextSpan(
        text: text,
        style: base.copyWith(
          height: base.height ?? 1.1,
          background: band,
          color: dark ? AppColors.onMood : base.color,
        ),
      ),
      textAlign: textAlign,
    );
  }
}

/// Small uppercase tracked label above a section ("THIS WEEK").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: 'Schibsted Grotesk',
        fontWeight: FontWeight.w700,
        fontSize: 11.5,
        letterSpacing: 1.1,
        color: cs.onSurfaceVariant,
      ),
    );
    if (trailing == null) return label;
    return Row(children: [Expanded(child: label), trailing!]);
  }
}

/// A journal text field drawn on ruled notebook lines.
class RuledTextField extends StatelessWidget {
  const RuledTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.maxLength,
    this.minLines = 4,
  });

  final TextEditingController controller;
  final String? hintText;
  final int? maxLength;
  final int minLines;

  static const _fontSize = 16.0;
  static const _lineHeight = 28.0;
  static const _topPad = 6.0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: CustomPaint(
        painter: _RulePainter(color: cs.outline, lineHeight: _lineHeight, top: _topPad),
        child: TextField(
          controller: controller,
          minLines: minLines,
          maxLines: 8,
          maxLength: maxLength,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(fontSize: _fontSize, height: _lineHeight / _fontSize, color: cs.onSurface),
          decoration: InputDecoration(
            hintText: hintText,
            filled: false,
            isCollapsed: true,
            contentPadding: const EdgeInsets.only(top: _topPad),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

class _RulePainter extends CustomPainter {
  _RulePainter({required this.color, required this.lineHeight, required this.top});

  final Color color;
  final double lineHeight;
  final double top;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    // Stop above the counter row that maxLength adds under the field.
    for (var y = top + lineHeight; y < size.height - 18; y += lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_RulePainter old) => old.color != color || old.lineHeight != lineHeight;
}
