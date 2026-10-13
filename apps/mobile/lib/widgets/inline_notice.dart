import 'package:flutter/material.dart';
import '../core/elevation.dart';

/// Calm inline error with a retry: muted rose tint, never an alarming red,
/// per CLAUDE.md. Shared by list-style screens.
class InlineNotice extends StatelessWidget {
  const InlineNotice({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, size: 20, color: cs.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: tt.bodyMedium?.copyWith(color: cs.onSurface),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
