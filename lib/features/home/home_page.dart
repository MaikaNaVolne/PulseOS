import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pulseos/core/utils/app_routes.dart';
import '../../core/ui_kit/pulse_page.dart';
import '../../core/ui_kit/pulse_buttons.dart';
import '../../core/theme/pulse_theme.dart';
import 'widgets/bento_grid.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Форматируем дату: "25 ОКТЯБРЯ"
    final dateStr = DateFormat('d MMMM', 'ru').format(DateTime.now());
    // День недели: "ПЯТНИЦА"
    final dayStr = DateFormat('EEEE', 'ru').format(DateTime.now());

    return PulsePage(
      title: "PulseOS",
      subtitle: "$dayStr, $dateStr", // Например: ПЯТНИЦА, 25 ОКТЯБРЯ
      accentColor: PulseColors.primary,

      // На главной кнопка назад не нужна
      showBackButton: false,

      // Кнопка настроек справа
      actions: [
        GlassCircleButton(
          icon: Icons.settings,
          onTap: () {
            // Обработка нажатия на кнопку настроек
            Navigator.pushNamed(context, AppRoutes.settings);
          },
        ),
      ],

      // Пустое тело (пока)
      body: Column(
        children: [
          const SizedBox(height: 10),
          const BentoGrid(),

          // Место для других виджетов (например, списка инструментов)
          const SizedBox(height: 20),
          const Center(
            child: Text(
              "Лента событий скоро появится...",
              style: TextStyle(color: Colors.white24),
            ),
          ),
        ],
      ),
    );
  }
}
