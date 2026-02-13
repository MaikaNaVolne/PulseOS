import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для виброотклика
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
  // Якорь текущей даты
  DateTime _selectedDate = DateTime.now();

  // Метод для переключения даты
  void _moveDate(int delta) {
    HapticFeedback.lightImpact(); // Стандарт PulseOS для кнопок
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: delta));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Красиво форматируем подзаголовок: "СЕГОДНЯ" или "15 ОКТЯБРЯ"
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    final dateLabel = isToday
        ? "СЕГОДНЯ"
        : DateFormat('d MMMM', 'ru').format(_selectedDate).toUpperCase();

    return PulsePage(
      title: "Сон",
      subtitle: dateLabel,
      accentColor: PulseColors.purple,
      useScroll: false,
      // Добавляем кнопки управления в хедер справа
      actions: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white54),
          onPressed: () => _moveDate(-1),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.white54),
          onPressed: isToday
              ? null
              : () => _moveDate(1), // Нельзя листать в будущее
        ),
      ],
      body: StreamBuilder<List<SleepEntry>>(
        stream: sl<AppDatabase>().sleepDao.watchAllSleep(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final allEntries = snapshot.data!;

          // 1. Фильтруем записи именно за ВЫБРАННЫЙ день
          final dayEntries = allEntries
              .where((e) => DateUtils.isSameDay(e.endTime, _selectedDate))
              .toList();

          // 2. Считаем ОБЩУЮ длительность
          double totalHours = 0;
          for (var e in dayEntries) {
            totalHours += e.endTime.difference(e.startTime).inMinutes / 60.0;
          }

          // 3. Выбираем главную сессию (ночную) для отображения деталей
          final mainEntry =
              dayEntries.where((e) => e.sleepType == 'night').firstOrNull ??
              (dayEntries.isNotEmpty ? dayEntries.first : null);

          return Stack(
            children: [
              if (dayEntries.isEmpty)
                _buildEmptyState(isToday)
              else
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    children: [
                      // КРУГ (Суммарные часы)
                      SleepHeroCard(totalHours: totalHours),

                      const SizedBox(height: 24),

                      // Метки сессий (если их больше одной)
                      if (dayEntries.length > 1) _buildSessionsList(dayEntries),

                      if (mainEntry != null) ...[
                        const SizedBox(height: 24),
                        SleepPhasesCard(entry: mainEntry),
                        const SizedBox(height: 24),
                        SleepStatsGrid(entry: mainEntry),
                        const SizedBox(height: 24),
                        SleepFeelingCard(entry: mainEntry),
                        const SizedBox(height: 24),
                        SleepFactorsCard(sleepId: mainEntry.id),
                      ],
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

  Widget _buildEmptyState(bool isToday) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Column(
          children: [
            Icon(
              Icons.bedtime_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.05),
            ),
            const SizedBox(height: 16),
            Text(
              isToday
                  ? "Вы еще не записали сон сегодня"
                  : "Записей за этот день нет",
              style: const TextStyle(color: Colors.white24),
            ),
          ],
        ),
      ),
    );
  }

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
                  .withValues(alpha: 0.2),
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
