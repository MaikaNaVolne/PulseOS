import 'package:flutter/material.dart';
import '../theme/pulse_theme.dart';

class PulseDismissible extends StatelessWidget {
  final String id;
  final Widget child;
  final VoidCallback onDismissed;

  const PulseDismissible({
    super.key,
    required this.id,
    required this.child,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(id),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: PulseColors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_sweep_outlined, color: PulseColors.red),
      ),
      onDismissed: (_) => onDismissed(),
      child: child,
    );
  }
}
