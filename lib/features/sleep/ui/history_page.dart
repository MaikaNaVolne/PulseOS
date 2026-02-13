import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/pulse_theme.dart';
import '../../../../core/ui_kit/pulse_page.dart';
import '../domain/models/weekly_sleep_stats.dart';
import 'diallogs/sleep_editor_dialog.dart';
import 'widgets/history_stats_row.dart';
import 'widgets/sleep_bar_chart.dart';

class SleepHistoryPage extends StatefulWidget {
  const SleepHistoryPage({super.key});

  @override
  State<SleepHistoryPage> createState() => _SleepHistoryPageState();
}

class _SleepHistoryPageState extends State<SleepHistoryPage> {
  DateTime _focusedWeek = DateTime.now();
  bool _showQuality = false; // Переключатель графика: Длительность / Качество

  void _moveWeek(int delta) {
    setState(() {
      _focusedWeek = _focusedWeek.add(Duration(days: delta * 7));
    });
  }

  @override
  Widget build(BuildContext context) {
    final startOfWeek = _focusedWeek.subtract(
      Duration(days: _focusedWeek.weekday - 1),
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return PulsePage(
      title: "История",
      subtitle:
          "${DateFormat('d MMM', 'ru').format(startOfWeek)} — ${DateFormat('d MMM', 'ru').format(endOfWeek)}",
      accentColor: PulseColors.purple,
      actions: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white54),
          onPressed: () => _moveWeek(-1),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.white54),
          onPressed: () => _moveWeek(1),
        ),
      ],
      body: StreamBuilder<List<SleepEntry>>(
        stream: sl<AppDatabase>().sleepDao.watchAllSleep(),
        builder: (context, snapshot) {
          final all = snapshot.data ?? [];
          // Фильтруем данные за выбранную неделю
          final weeklyEntries = all
              .where(
                (e) =>
                    e.endTime.isAfter(
                      startOfWeek.subtract(const Duration(seconds: 1)),
                    ) &&
                    e.endTime.isBefore(
                      endOfWeek.add(const Duration(hours: 23)),
                    ),
              )
              .toList();

          final stats = WeeklySleepStats(
            entries: weeklyEntries,
            weekStart: startOfWeek,
          );

          return Column(
            children: [
              // 1. СТАТИСТИКА (Bento-стиль)
              HistoryStatsRow(stats: stats),

              const SizedBox(height: 24),

              // 2. ГРАФИК (Столбчатый)
              SleepBarChart(
                entries: weeklyEntries,
                weekStart: startOfWeek,
                isQualityMode: _showQuality,
                onToggle: () => setState(() => _showQuality = !_showQuality),
              ),

              const SizedBox(height: 32),

              // 3. СПИСОК ЗАПИСЕЙ
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "ЗАПИСИ",
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              ...weeklyEntries.map((e) => _HistoryTile(entry: e)),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final SleepEntry entry;
  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final duration = entry.endTime.difference(entry.startTime).inMinutes / 60.0;
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => SleepEditorDialog(entry: entry),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Column(
              children: [
                Text(
                  DateFormat('E', 'ru').format(entry.endTime).toUpperCase(),
                  style: const TextStyle(
                    color: PulseColors.purple,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('d', 'ru').format(entry.endTime),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.sleepType == 'night' ? "Ночной сон" : "Дневной сон",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    "${duration.toStringAsFixed(1)}ч • Качество: ${entry.quality}/10",
                    style: const TextStyle(color: Colors.white24, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, color: Colors.white10, size: 18),
          ],
        ),
      ),
    );
  }
}
