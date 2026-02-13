import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/pulse_theme.dart';
import '../../../../core/database/app_database.dart';

class SleepBarChart extends StatelessWidget {
  final List<SleepEntry> entries;
  final DateTime weekStart;
  final bool isQualityMode;
  final VoidCallback onToggle;

  const SleepBarChart({
    super.key,
    required this.entries,
    required this.weekStart,
    required this.isQualityMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isQualityMode ? "ДИНАМИКА КАЧЕСТВА" : "ДЛИТЕЛЬНОСТЬ ПО ДНЯМ",
              style: const TextStyle(
                color: Colors.white24,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: onToggle,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: PulseColors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isQualityMode ? "Показать часы" : "Показать качество",
                  style: const TextStyle(
                    color: PulseColors.purple,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: isQualityMode ? 10 : 12,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      final day = DateFormat(
                        'E',
                        'ru',
                      ).format(weekStart.add(Duration(days: val.toInt())));
                      return Text(
                        day,
                        style: const TextStyle(
                          color: Colors.white24,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(7, (i) {
                final day = weekStart.add(Duration(days: i));
                final dayEntries = entries
                    .where((e) => DateUtils.isSameDay(e.endTime, day))
                    .toList();

                double value = 0;
                if (dayEntries.isNotEmpty) {
                  if (isQualityMode) {
                    value =
                        dayEntries.fold(0, (sum, e) => sum + e.quality) /
                        dayEntries.length;
                  } else {
                    value = dayEntries.fold(
                      0.0,
                      (sum, e) =>
                          sum +
                          (e.endTime.difference(e.startTime).inMinutes / 60.0),
                    );
                  }
                }

                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: value,
                      color: isQualityMode
                          ? PulseColors.purple
                          : PulseColors.primary,
                      width: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
