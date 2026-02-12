import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // Для русской локали
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:pulseos/core/utils/app_routes.dart';
import 'package:pulseos/features/wallet/ui/category/category_page.dart';
import 'package:pulseos/features/wallet/wallet_page.dart';
import 'core/di/service_locator.dart';
import 'core/theme/pulse_theme.dart';
import 'features/home/home_page.dart';
import 'features/settings/settings_page.dart';
import 'features/wallet/presentation/wallet_provider.dart';
import 'features/wallet/ui/history/transaction_history_page.dart';
import 'features/wallet/ui/reports/wallet_report_page.dart';
import 'features/wallet/ui/shop/shops_page.dart';
import 'features/wallet/ui/transactions/transaction_editor_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);
  await initServices(); // База данных

  runApp(
    MultiProvider(
      providers: [
        // Регистрируем наш кошелек
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: const PulseApp(),
    ),
  );
}

class PulseApp extends StatelessWidget {
  const PulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PulseOS',
      debugShowCheckedModeBanner: false,
      theme: PulseTheme.darkTheme,

      // Настройки локализации
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'), // Русский
      ],
      locale: const Locale(
        'ru',
        'RU',
      ), // Устанавливаем русский язык принудительно
      // Маршрутизация
      initialRoute: '/',
      routes: {
        AppRoutes.home: (context) => const HomePage(),
        AppRoutes.settings: (context) => const SettingsPage(),
        AppRoutes.wallet: (context) => const WalletPage(),
        AppRoutes.transaction: (context) => const TransactionEditorPage(),
        AppRoutes.category: (context) => const CategoryPage(),
        AppRoutes.history: (context) => const TransactionHistoryPage(),
        AppRoutes.reports: (context) => const WalletReportPage(),
        AppRoutes.shops: (context) => const ShopsPage(),
      },
    );
  }
}
