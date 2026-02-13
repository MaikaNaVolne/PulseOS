import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_theme.dart';

class SleepHeroCard extends StatelessWidget {
  final double totalHours; // <--- ПРИНИМАЕМ ЧИСЛО
  const SleepHeroCard({super.key, required this.totalHours});

  @override
  Widget build(BuildContext context) {
    final hours = totalHours.floor();
    final minutes = ((totalHours - hours) * 60).round();
    final progress = (totalHours / 8.5).clamp(0.0, 1.0); // Идеал 8.5 часов

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 210,
            height: 210,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 10,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.white.withValues(alpha: 0.03),
              color: PulseColors.purple,
            ),
          ),
          Column(
            children: [
              Text(
                "${hours}ч ${minutes}м",
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const Text(
                "ВСЕГО ЗА СУТКИ",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
