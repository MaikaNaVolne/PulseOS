import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/pulse_theme.dart';
import '../../../../core/database/app_database.dart';

class SleepStatsGrid extends StatelessWidget {
  final SleepEntry entry;
  const SleepStatsGrid({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildItem(
          "ЛЕГ",
          DateFormat('HH:mm').format(entry.startTime),
          PulseColors.blue,
        ),
        const SizedBox(width: 12),
        _buildItem(
          "ВСТАЛ",
          DateFormat('HH:mm').format(entry.endTime),
          PulseColors.orange,
        ),
        const SizedBox(width: 12),
        _buildItem("КАЧЕСТВО", "${entry.quality}/10", PulseColors.purple),
      ],
    );
  }

  Widget _buildItem(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white24,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              val,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
