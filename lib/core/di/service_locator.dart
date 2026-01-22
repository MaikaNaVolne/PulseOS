import 'package:get_it/get_it.dart';
import '../database/app_database.dart';
import '../services/settings_service.dart';

// Глобальная переменная для доступа
final sl = GetIt.instance;

Future<void> initServices() async {
  // В initServices()
  final settings = await SettingsService.init();
  sl.registerSingleton<SettingsService>(settings);
  // Регистрируем базу данных как Singleton (одна на всё приложение)
  // Используем обычный конструктор (не memory), чтобы данные сохранялись
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());
}
