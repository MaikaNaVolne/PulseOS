import 'package:flutter/material.dart';
import '../../core/database/app_database.dart';
import '../../core/di/service_locator.dart';
import '../../core/theme/pulse_theme.dart';
import '../../core/ui_kit/pulse_page.dart';
import 'ui/widgets/sleep_bottom_dock.dart';
import 'ui/widgets/sleep_factors_card.dart';
import 'ui/widgets/sleep_feeling_card.dart';
import 'ui/widgets/sleep_hero_card.dart';
import 'ui/widgets/sleep_phases_card.dart';
import 'ui/widgets/sleep_stats_grid.dart';

class SleepPage extends StatelessWidget {
  const SleepPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PulsePage(
      title: "Сон",
      subtitle: "ОТЧЕТ ЗА НОЧЬ",
      accentColor: PulseColors.purple,
      // Отключаем стандартный скролл PulsePage, чтобы сделать кастомный док
      useScroll: false,
      body: StreamBuilder<List<SleepEntry>>(
        stream: sl<AppDatabase>().sleepDao.watchAllSleep(),
        builder: (context, snapshot) {
          final entries = snapshot.data ?? [];
          // Берем самую свежую запись
          final lastSleep = entries.isNotEmpty ? entries.first : null;

          return Stack(
            children: [
              // Основной контент
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120), // Место под док
                child: Column(
                  children: [
                    if (lastSleep != null) ...[
                      // 1. КРУГ С ЧАСАМИ
                      SleepHeroCard(entry: lastSleep),

                      const SizedBox(height: 24),

                      // 2. ФАЗЫ СНА (Визуализация)
                      SleepPhasesCard(entry: lastSleep),

                      const SizedBox(height: 24),

                      // 3. СЕТКА: ЛЕГ | ВСТАЛ | КАЧЕСТВО
                      SleepStatsGrid(entry: lastSleep),

                      const SizedBox(height: 24),

                      // 4. САМОЧУВСТВИЕ (Слайдеры из старого кода)
                      SleepFeelingCard(entry: lastSleep),

                      const SizedBox(height: 24),

                      // 5. ФАКТОРЫ (Теги)
                      SleepFactorsCard(sleepId: lastSleep.id),
                    ] else
                      const _SleepEmptyState(),
                  ],
                ),
              ),

              // 6. НИЖНИЙ ДОК (Переключатели)
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
}

class _SleepEmptyState extends StatelessWidget {
  const _SleepEmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Text(
          "Нет данных о сне",
          style: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
        ),
      ),
    );
  }
}
