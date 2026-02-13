import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_theme.dart';
import '../../domain/models/weekly_sleep_stats.dart';

class HistoryStatsRow extends StatelessWidget {
  final WeeklySleepStats stats;
  const HistoryStatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _item(
          "СР. СОН",
          "${stats.avgDuration.toStringAsFixed(1)}ч",
          PulseColors.blue,
        ),
        const SizedBox(width: 10),
        _item(
          "КАЧЕСТВО",
          "${stats.avgQuality.toStringAsFixed(1)}",
          PulseColors.purple,
        ),
        const SizedBox(width: 10),
        _item("ЗАПИСЕЙ", "${stats.totalCount}", PulseColors.orange),
      ],
    );
  }

  Widget _item(String label, String val, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: col.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white24,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              val,
              style: TextStyle(
                color: col,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
