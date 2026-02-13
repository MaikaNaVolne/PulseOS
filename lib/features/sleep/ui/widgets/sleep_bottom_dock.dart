import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_theme.dart';

class SleepBottomDock extends StatelessWidget {
  const SleepBottomDock({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E202C).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DockItem(icon: Icons.history, label: "История"),
                _DockItem(icon: Icons.calculate_outlined, label: "Калькулятор"),
                _AddSleepButton(),
                _DockItem(icon: Icons.settings_outlined, label: "Цели"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DockItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white54, size: 22),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 9)),
      ],
    );
  }
}

class _AddSleepButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: PulseColors.purple,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 24),
    );
  }
}
