import 'package:flutter/material.dart';
import 'package:pulseos/core/ui_kit/pulse_page.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PulsePage(
      title: "Кошелек",
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
