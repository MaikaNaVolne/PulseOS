import 'package:flutter/material.dart';
import '../../core/ui_kit/pulse_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PulsePage(
      title: 'Настройки',
      subtitle: 'Настройки',
      showBackButton: true,

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.grid_view,
              size: 48,
              color: Colors.white.withValues(alpha: .1),
            ),
            const SizedBox(height: 16),
            Text(
              "Добро пожаловать",
              style: TextStyle(
                color: Colors.white.withValues(alpha: .3),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
