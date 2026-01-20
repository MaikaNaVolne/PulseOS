import 'package:flutter/material.dart';
import '../../../../core/ui_kit/pulse_page.dart';
import '../../../../core/ui_kit/pulse_buttons.dart';
import '../../../../core/theme/pulse_theme.dart';

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PulsePage(
      title: "История",
      subtitle: "ОПЕРАЦИИ",
      accentColor: PulseColors.primary,
      showBackButton: true,

      // Кнопка поиска
      actions: [GlassCircleButton(icon: Icons.search, onTap: () {})],

      body: const Center(
        child: Text(
          "Скоро здесь будет история",
          style: TextStyle(color: Colors.white24),
        ),
      ),
    );
  }
}
