import 'package:flutter/material.dart';
import '../../../../core/ui_kit/pulse_page.dart';
import '../../../../core/theme/pulse_theme.dart';
import '../../../../core/ui_kit/pulse_buttons.dart';

class PlanningPage extends StatelessWidget {
  const PlanningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PulsePage(
      title: "План",
      subtitle: "БУДУЩИЕ ТРАТЫ",
      accentColor: PulseColors.purple,
      showBackButton: true,
      // Кнопка добавления нового плана
      actions: [
        GlassCircleButton(
          icon: Icons.add,
          onTap: () {
            // Откроем редактор на Шаге 4
          },
        ),
      ],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            const Text(
              "План на месяц пуст",
              style: TextStyle(color: Colors.white24, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
