import 'dart:convert';
import 'package:http/http.dart' as http;
import '../presentation/wallet_provider.dart'; // Для DTO

class ReceiptData {
  final DateTime date;
  final String? shopName;
  final List<TransactionItemDto> items;

  ReceiptData({required this.date, this.shopName, required this.items});
}

class ReceiptService {
  static const String _apiUrl = "https://proverkacheka.com/api/v1/check/get";

  /// Возвращает данные чека или выбрасывает исключение
  static Future<ReceiptData> getReceipt({
    required String qrRaw,
    required String token,
  }) async {
    if (token.isEmpty) throw Exception("Токен не найден");

    final response = await http.post(
      Uri.parse(_apiUrl),
      body: {"token": token, "qrraw": qrRaw},
    );

    if (response.statusCode != 200) {
      throw Exception("Ошибка сети: ${response.statusCode}");
    }

    final jsonResponse = jsonDecode(response.body);
    final int code = jsonResponse['code'] ?? 0;

    if (code != 1) {
      // Код 1 = Успех. Остальное - ошибки (нет чека в ФНС, плохой токен и т.д.)
      throw Exception(
        "Ошибка API (Код $code): ${jsonResponse['message'] ?? 'Неизвестная ошибка'}",
      );
    }

    final data = jsonResponse['data'];
    final jsonContent = data['json'];

    if (jsonContent == null) {
      throw Exception("Чек найден, но данные пустые.");
    }

    // 1. Парсим дату
    DateTime date = DateTime.now();
    if (jsonContent.containsKey('dateTime')) {
      // Формат API может быть ISO8601 или timestamp
      try {
        date = DateTime.parse(jsonContent['dateTime']);
      } catch (_) {}
    }

    // 2. Парсим магазин
    String? shopName = jsonContent['retailPlace'] ?? jsonContent['user'];

    // 3. Парсим товары
    final List<dynamic> jsonItems = jsonContent['items'] ?? [];
    final items = jsonItems.map((item) {
      // Цена в API приходит в копейках (39999), нам нужны рубли (399.99)
      final double price = (item['price'] as num).toDouble() / 100.0;
      final double qty = (item['quantity'] as num).toDouble();
      final String name = item['name'] ?? "Товар";

      return TransactionItemDto(
        name: name,
        price: price,
        quantity: qty,
        tags: [], // Теги будем ставить руками
      );
    }).toList();

    return ReceiptData(date: date, shopName: shopName, items: items);
  }
}
