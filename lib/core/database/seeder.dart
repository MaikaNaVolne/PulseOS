// lib/core/database/seeder.dart
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:pulseos/core/database/app_database.dart';
import 'package:uuid/uuid.dart';

class WalletSeeder {
  final AppDatabase db;

  WalletSeeder(this.db);

  /// Запускает генерацию данных
  Future<void> seed() async {
    print("🌱 SEEDER: Начало генерации данных...");

    // 1. Проверяем или создаем тестовый счет
    final accountId = await _ensureAccount();

    // 2. Генерируем "Пятерочку" (Продукты, частые покупки, рост цен)
    await _generateShopHistory(
      accountId: accountId,
      shopName: "Пятерочка",
      categoryName: "Продукты",
      itemsHistory: {
        "Молоко Домик": [
          _PricePoint(date: _monthsAgo(12), price: 89.99),
          _PricePoint(date: _monthsAgo(6), price: 95.50),
          _PricePoint(date: _monthsAgo(1), price: 109.99),
        ],
        "Хлеб Бородинский": [
          _PricePoint(date: _monthsAgo(12), price: 45.00),
          _PricePoint(date: _monthsAgo(1), price: 52.00),
        ],
        "Бананы (кг)": [
          _PricePoint(date: _monthsAgo(6), price: 120.00),
          _PricePoint(date: _daysAgo(2), price: 145.00),
        ],
      },
      randomVisits: 15, // Случайные мелкие покупки
    );

    // 3. Генерируем "Лукойл" (Топливо, стабильный рост)
    await _generateShopHistory(
      accountId: accountId,
      shopName: "Лукойл",
      categoryName: "Авто",
      itemsHistory: {
        "АИ-95": [
          _PricePoint(date: _monthsAgo(24), price: 52.50),
          _PricePoint(date: _monthsAgo(12), price: 55.40),
          _PricePoint(date: _monthsAgo(6), price: 58.90),
          _PricePoint(date: _daysAgo(5), price: 61.20),
        ],
      },
      randomVisits: 5,
    );

    // 4. Генерируем "Ozon" (Техника, редкие покупки, разные товары)
    await _generateShopHistory(
      accountId: accountId,
      shopName: "Ozon",
      categoryName: "Маркетплейсы",
      itemsHistory: {
        "SSD Samsung 1TB": [
          _PricePoint(date: _monthsAgo(18), price: 8500.00),
          _PricePoint(date: _monthsAgo(1), price: 7200.00), // Подешевел
        ],
      },
      // Просто случайные покупки без истории цен
      extraItems: [
        _SimpleItem("Чехол для телефона", 500, _monthsAgo(3)),
        _SimpleItem("Книга Flutter", 1500, _monthsAgo(2)),
        _SimpleItem("Корм для кота", 3000, _daysAgo(10)),
      ],
    );

    print("✅ SEEDER: Готово! База данных заполнена.");
  }

  // --- ХЕЛПЕРЫ ---

  DateTime _monthsAgo(int months) =>
      DateTime.now().subtract(Duration(days: 30 * months));
  DateTime _daysAgo(int days) => DateTime.now().subtract(Duration(days: days));

  Future<String> _ensureAccount() async {
    // Ищем любой счет, если нет - создаем
    final accounts = await db.select(db.accounts).get();
    if (accounts.isNotEmpty) return accounts.first.id;

    final id = const Uuid().v4();
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: id,
            name: "Основная карта",
            type: "card",
            currencyCode: "RUB",
            balance: Value(BigInt.from(5000000)), // 50k
            isMain: const Value(true),
          ),
        );
    return id;
  }

  Future<String> _ensureCategory(String name) async {
    final cats = await (db.select(
      db.categories,
    )..where((t) => t.name.equals(name))).get();
    if (cats.isNotEmpty) return cats.first.id;

    final id = const Uuid().v4();
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: id,
            name: name,
            colorHex: "#808080",
            iconKey: const Value("shopping"),
          ),
        );
    return id;
  }

  Future<void> _generateShopHistory({
    required String accountId,
    required String shopName,
    required String categoryName,
    Map<String, List<_PricePoint>>? itemsHistory,
    List<_SimpleItem>? extraItems,
    int randomVisits = 0,
  }) async {
    final catId = await _ensureCategory(categoryName);
    final random = Random();

    // 1. Создаем транзакции по истории цен
    if (itemsHistory != null) {
      for (var entry in itemsHistory.entries) {
        final itemName = entry.key;
        for (var point in entry.value) {
          await _createTransaction(
            accountId: accountId,
            categoryId: catId,
            shopName: shopName,
            date: point.date,
            items: [
              // Цена * кол-во (иногда покупаем 2 шт для разнообразия)
              _ItemData(
                name: itemName,
                price: point.price,
                qty: random.nextBool() ? 1 : 2,
              ),
            ],
          );
        }
      }
    }

    // 2. Создаем одиночные покупки
    if (extraItems != null) {
      for (var item in extraItems) {
        await _createTransaction(
          accountId: accountId,
          categoryId: catId,
          shopName: shopName,
          date: item.date,
          items: [_ItemData(name: item.name, price: item.price, qty: 1)],
        );
      }
    }

    // 3. Генерируем "шум" (случайные визиты в этот магазин)
    for (int i = 0; i < randomVisits; i++) {
      final date = DateTime.now().subtract(Duration(days: random.nextInt(90)));
      await _createTransaction(
        accountId: accountId,
        categoryId: catId,
        shopName: shopName,
        date: date,
        items: [
          _ItemData(name: "Пакет", price: 10.0, qty: 1),
          _ItemData(
            name: "Случайный товар ${i + 1}",
            price: (100 + random.nextInt(500)).toDouble(),
            qty: 1,
          ),
        ],
      );
    }
  }

  Future<void> _createTransaction({
    required String accountId,
    required String categoryId,
    required String shopName,
    required DateTime date,
    required List<_ItemData> items,
  }) async {
    final transId = const Uuid().v4();

    // Считаем сумму в копейках
    double total = 0;
    for (var i in items) total += (i.price * i.qty);
    final amountBigInt = BigInt.from((total * 100).round());

    // Транзакция
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: transId,
            type: 'expense',
            sourceAccountId: accountId,
            categoryId: Value(categoryId),
            amount: amountBigInt,
            date: date,
            shopName: Value(shopName),
          ),
        );

    // Товары
    for (var item in items) {
      await db
          .into(db.transactionItems)
          .insert(
            TransactionItemsCompanion.insert(
              id: const Uuid().v4(),
              transactionId: transId,
              name: item.name,
              price: BigInt.from((item.price * 100).round()),
              quantity: Value(item.qty.toDouble()),
              categoryId: Value(categoryId),
            ),
          );
    }
  }
}

// Вспомогательные классы для сидера
class _PricePoint {
  final DateTime date;
  final double price;
  _PricePoint({required this.date, required this.price});
}

class _SimpleItem {
  final String name;
  final double price;
  final DateTime date;
  _SimpleItem(this.name, this.price, this.date);
}

class _ItemData {
  final String name;
  final double price;
  final int qty;
  _ItemData({required this.name, required this.price, required this.qty});
}
