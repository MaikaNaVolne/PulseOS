import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_theme.dart';
import '../../../../core/database/app_database.dart';

class SleepFeelingCard extends StatelessWidget {
  final SleepEntry entry;
  const SleepFeelingCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildSlider(
            "Глубина сна",
            entry.quality.toDouble(),
            PulseColors.purple,
          ),
          const SizedBox(height: 16),
          _buildSlider(
            "Легкость подъема",
            entry.wakeEase.toDouble(),
            PulseColors.orange,
          ),
          const SizedBox(height: 16),
          _buildSlider(
            "Бодрость днем",
            entry.energyLevel.toDouble(),
            PulseColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            Text(
              "${val.toInt()}/10",
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: val / 10,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            color: color,
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
