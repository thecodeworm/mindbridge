import 'package:flutter/material.dart';

/// Scroll the step content while keeping the primary action within reach.
class NotebookStep extends StatelessWidget {
  const NotebookStep({super.key, required this.children, required this.action});

  final List<Widget> children;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 24, bottom: 24),
              children: children,
            ),
          ),
          action,
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
