import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_theme.dart';

class AddSleepSheet extends StatelessWidget {
  final VoidCallback onTimer;
  final VoidCallback onNight;
  final VoidCallback onNap;

  const AddSleepSheet({
    super.key,
    required this.onTimer,
    required this.onNight,
    required this.onNap,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161821).withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Полоска сверху
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            _buildOption(
              icon: Icons.timer_outlined,
              title: "Таймер сна",
              subtitle: "Запустить отслеживание в реальном времени",
              color: PulseColors.purple,
              onTap: onTimer,
            ),
            const SizedBox(height: 12),
            _buildOption(
              icon: Icons.nightlight_round,
              title: "Ночной сон",
              subtitle: "Добавить запись вручную за прошлую ночь",
              color: PulseColors.blue,
              onTap: onNight,
            ),
            const SizedBox(height: 12),
            _buildOption(
              icon: Icons.wb_sunny_outlined,
              title: "Дневной сон",
              subtitle: "Короткий отдых (Nap) в течение дня",
              color: PulseColors.orange,
              onTap: onNap,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white10),
          ],
        ),
      ),
    );
  }
}
