import 'package:flutter/material.dart';

/// Pill toggle with an outlined/filled icon pair, used for the coping
/// suggestion's Helpful / Not for me / Save controls.
class FeedbackChip extends StatelessWidget {
  const FeedbackChip({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: active,
      child: Material(
        color: active ? cs.primaryContainer : cs.surface,
        shape: StadiumBorder(
          side: BorderSide(color: active ? cs.primary : cs.outline),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active ? activeIcon : icon,
                  size: 18,
                  color: active ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: tt.labelLarge?.copyWith(
                    color: active ? cs.primary : cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
