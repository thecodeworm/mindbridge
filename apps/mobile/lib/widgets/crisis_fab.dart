import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../features/help/help_screen.dart';

/// Persistent, always-visible crisis affordance, per
/// docs/research/00-design-direction.md §8 and CLAUDE.md's crisis rule:
/// a soft-bordered terracotta chip, never a red banner.
///
/// Lives in each screen's top bar (AppBar `actions`, or the header row on
/// screens without an AppBar) rather than as a floating button, because a
/// FAB sat on top of list content and bottom-pinned buttons.
class HelpChip extends StatelessWidget {
  const HelpChip({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final terraDark = isDark ? AppColors.dTerraDark : AppColors.terraDark;
    final terraTint = isDark ? AppColors.dTerraTint : AppColors.terraTint;
    final terra = isDark ? AppColors.dTerra : AppColors.terra;

    return Semantics(
      button: true,
      label: 'Get help now. Crisis resources.',
      child: Tooltip(
        message: 'Crisis resources & help',
        child: Material(
          color: terraTint,
          shape: StadiumBorder(
            side: BorderSide(color: terra.withValues(alpha: 0.6)),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_outline, size: 16, color: terraDark),
                  const SizedBox(width: 6),
                  Text(
                    'Help',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: terraDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// [HelpChip] with trailing spacing, for an AppBar's `actions` list.
class HelpAction extends StatelessWidget {
  const HelpAction({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 16),
      child: Center(child: HelpChip()),
    );
  }
}
