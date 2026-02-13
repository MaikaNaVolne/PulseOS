import 'package:flutter/material.dart';
import '../../core/database/app_database.dart';
import '../../core/database/seeder.dart';
import '../../core/di/service_locator.dart';
import '../../core/ui_kit/pulse_button.dart';
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
            PulseButton(
              text: "СГЕНЕРИРОВАТЬ ДАННЫЕ (DEV)",
              color: Colors.orange,
              onPressed: () async {
                final db = sl<AppDatabase>();
                final seeder = WalletSeeder(db);
                await seeder.seed();
                await seeder.seedPlanning();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Данные сгенерированы!")),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
