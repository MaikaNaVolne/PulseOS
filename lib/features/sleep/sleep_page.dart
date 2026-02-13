import 'package:flutter/material.dart';
import '../../core/ui_kit/pulse_page.dart';
import '../../core/theme/pulse_theme.dart';

class SleepPage extends StatelessWidget {
  const SleepPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PulsePage(
      title: "Сон",
      subtitle: "ОТДЫХ И ВОССТАНОВЛЕНИЕ",
      accentColor: PulseColors.purple,
      showBackButton: true,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.nightlight_round,
              size: 64,
              color: PulseColors.purple.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            const Text(
              "Анализ сна скоро появится",
              style: TextStyle(color: Colors.white24, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
