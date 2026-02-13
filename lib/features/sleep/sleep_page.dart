import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/app_database.dart';
import '../../core/di/service_locator.dart';
import '../../core/theme/pulse_theme.dart';
import '../../core/ui_kit/pulse_page.dart';
import 'ui/widgets/sleep_hero_card.dart';
import 'ui/widgets/sleep_stats_grid.dart';
import 'ui/widgets/sleep_phases_card.dart';
import 'ui/widgets/sleep_feeling_card.dart';
import 'ui/widgets/sleep_factors_card.dart';
import 'ui/widgets/sleep_bottom_dock.dart';

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  // По умолчанию смотрим за сегодня
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return PulsePage(
      title: "Сон",
      subtitle: DateFormat('d MMMM', 'ru').format(_selectedDate).toUpperCase(),
      accentColor: PulseColors.purple,
      useScroll: false,
      body: StreamBuilder<List<SleepEntry>>(
        stream: sl<AppDatabase>().sleepDao.watchAllSleep(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final allEntries = snapshot.data!;

          // 1. Фильтруем записи именно за выбранный день
          final dayEntries = allEntries
              .where((e) => DateUtils.isSameDay(e.endTime, _selectedDate))
              .toList();

          // 2. Считаем ОБЩУЮ длительность (Сумма всех снов за день)
          double totalHours = 0;
          for (var e in dayEntries) {
            totalHours += e.endTime.difference(e.startTime).inMinutes / 60.0;
          }

          // 3. Находим основной (ночной) сон для отображения деталей (слайдеров и факторов)
          // Если ночного нет, берем самый длинный дневной
          final mainEntry = dayEntries.firstWhere(
            (e) => e.sleepType == 'night',
            orElse: () => dayEntries.isNotEmpty
                ? dayEntries.first
                : allEntries.first, // Заглушка
          );

          return Stack(
            children: [
              if (dayEntries.isEmpty)
                const _SleepEmptyState()
              else
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    children: [
                      // КРУГ ТЕПЕРЬ ПРИНИМАЕТ ОБЩУЮ СУММУ ЧАСОВ
                      SleepHeroCard(totalHours: totalHours),

                      const SizedBox(height: 24),

                      // Если есть несколько записей (напр. ночь + дневной), покажем мини-список
                      if (dayEntries.length > 1) _buildSessionsList(dayEntries),

                      const SizedBox(height: 24),

                      // Детали показываем по "главному" сну дня
                      SleepPhasesCard(entry: mainEntry),
                      const SizedBox(height: 24),
                      SleepStatsGrid(entry: mainEntry),
                      const SizedBox(height: 24),
                      SleepFeelingCard(entry: mainEntry),
                      const SizedBox(height: 24),
                      SleepFactorsCard(sleepId: mainEntry.id),
                    ],
                  ),
                ),

              const Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: SleepBottomDock(),
              ),
            ],
          );
        },
      ),
    );
  }

  // Маленький список сессий под кругом
  Widget _buildSessionsList(List<SleepEntry> entries) {
    return Wrap(
      spacing: 8,
      children: entries.map((e) {
        final isNight = e.sleepType == 'night';
        final duration = e.endTime.difference(e.startTime).inMinutes / 60.0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isNight ? PulseColors.purple : PulseColors.orange)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            "${isNight ? '🌙' : '☀️'} ${duration.toStringAsFixed(1)}ч",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SleepEmptyState extends StatelessWidget {
  const _SleepEmptyState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 100),
        child: Text(
          "Записей за этот день нет",
          style: TextStyle(color: Colors.white24),
        ),
      ),
    );
  }
}
