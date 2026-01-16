import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // Для русской локали
import 'package:pulseos/core/utils/app_routes.dart';
import 'package:pulseos/features/wallet/wallet_page.dart';
import 'core/theme/pulse_theme.dart';
import 'features/home/home_page.dart';
import 'features/settings/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация локали для дат
  await initializeDateFormatting('ru', null);

  runApp(const PulseApp());
}

class PulseApp extends StatelessWidget {
  const PulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PulseOS',
      debugShowCheckedModeBanner: false,
      theme: PulseTheme.darkTheme,

      // Маршрутизация
      initialRoute: '/',
      routes: {
        AppRoutes.home: (context) => const HomePage(),
        AppRoutes.settings: (context) => const SettingsPage(),
        AppRoutes.wallet: (context) => const WalletPage(),
      },
    );
  }
}
