import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/pulse_theme.dart';

class PlanningChart extends StatelessWidget {
  const PlanningChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.only(top: 20),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            // План (Пунктир)
            LineChartBarData(
              spots: [
                const FlSpot(0, 3),
                const FlSpot(2, 5),
                const FlSpot(4, 4),
                const FlSpot(6, 8),
              ],
              isCurved: true,
              dashArray: [5, 5],
              color: PulseColors.purple.withValues(alpha: 0.3),
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),
            // Факт (Сплошная)
            LineChartBarData(
              spots: [
                const FlSpot(0, 2),
                const FlSpot(2, 4),
                const FlSpot(4, 5),
              ],
              isCurved: true,
              color: PulseColors.primary,
              barWidth: 4,
              belowBarData: BarAreaData(
                show: true,
                color: PulseColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
