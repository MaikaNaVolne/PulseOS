import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_theme.dart';
import '../../../../core/database/app_database.dart';

class SleepHeroCard extends StatelessWidget {
  final SleepEntry entry;
  const SleepHeroCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final duration = entry.endTime.difference(entry.startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final progress = (duration.inMinutes / 480).clamp(
      0.0,
      1.0,
    ); // 8 часов - идеал

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Внешнее кольцо
          SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 12,
              strokeCap: StrokeCap.round,
              backgroundColor: PulseColors.purple.withValues(alpha: 0.1),
              color: PulseColors.purple,
            ),
          ),
          // Текст внутри
          Column(
            children: [
              Text(
                "$hoursч $minutesм",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const Text(
                "ВРЕМЯ СНА",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
