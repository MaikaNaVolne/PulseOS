import 'package:flutter/material.dart';
import '../../../../core/ui_kit/pulse_page.dart';
import '../../../../core/theme/pulse_theme.dart';

class ShopsPage extends StatelessWidget {
  const ShopsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PulsePage(
      title: "Магазины",
      subtitle: "МЕСТА ПОКУПОК",
      accentColor: PulseColors.blue,
      showBackButton: true,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            const Text(
              "Список магазинов пуст",
              style: TextStyle(color: Colors.white24, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
