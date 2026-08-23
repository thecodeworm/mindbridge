import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../features/help/help_screen.dart';

/// Persistent, always-visible crisis affordance (Wysa's SOS-button pattern),
/// per docs/research/00-design-direction.md §8 — not confined to
/// entry-detail. Small and unobtrusive by design: terra-tint, never a red
/// banner, per CLAUDE.md's crisis-affordance rule.
class CrisisFab extends StatelessWidget {
  const CrisisFab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final terraDark = isDark ? AppColors.dTerraDark : AppColors.terraDark;
    final terraTint = isDark ? AppColors.dTerraTint : AppColors.terraTint;

    return FloatingActionButton(
      mini: true,
      heroTag: null,
      tooltip: 'Crisis resources & help',
      backgroundColor: terraTint,
      foregroundColor: terraDark,
      elevation: 2,
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HelpScreen()),
      ),
      child: const Icon(Icons.health_and_safety_outlined),
    );
  }
}
