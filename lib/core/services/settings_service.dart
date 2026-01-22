import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyReceiptToken = 'proverkacheka_token';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  // Получить токен (может быть null)
  String? get receiptToken => _prefs.getString(_keyReceiptToken);

  // Сохранить токен
  Future<void> setReceiptToken(String token) async {
    await _prefs.setString(_keyReceiptToken, token);
  }

  // Проверка: есть ли токен
  bool get hasToken => receiptToken != null && receiptToken!.isNotEmpty;

  // Инициализация (статический метод для main.dart)
  static Future<SettingsService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }
}
