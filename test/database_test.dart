import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift; // Для Value и Table
import 'package:drift/native.dart'; // Для in-memory базы
import 'package:pulseos/core/database/app_database.dart'; // Импорт твоей базы

void main() {
  late AppDatabase db;

  // Запускается ПЕРЕД каждым тестом
  setUp(() {
    // Создаем базу в памяти (она исчезнет после теста)
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  // Запускается ПОСЛЕ каждого теста
  tearDown(() async {
    await db.close();
  });

  test(
    'Wallet Flow: Create Currency -> Category -> Account -> Transaction',
    () async {
      // 1. Создаем валюту
      await db
          .into(db.currencies)
          .insert(
            CurrenciesCompanion.insert(
              code: 'RUB',
              name: 'Rubles',
              symbol: '₽',
            ),
          );

      // 2. Создаем категорию
      final catId = 'cat_1';
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: catId,
              name: 'Food',
              colorHex: '#FFFFFF',
            ),
          );

      // 3. Создаем счет
      final accId = 'acc_1';
      await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: accId,
              name: 'Main Card',
              type: 'card',
              currencyCode: 'RUB',
              balance: drift.Value(BigInt.from(100000)), // 1000.00
            ),
          );

      // 4. Создаем транзакцию
      final transId = 'trans_1';
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: transId,
              type: 'expense',
              sourceAccountId: accId,
              categoryId: drift.Value(catId),
              amount: BigInt.from(5000), // 50.00
              date: DateTime.now(),
            ),
          );

      // 5. ПРОВЕРЯЕМ (ASSERT)

      // Проверяем, что транзакция создалась
      final transaction = await (db.select(
        db.transactions,
      )..where((tbl) => tbl.id.equals(transId))).getSingle();
      expect(transaction.amount, equals(BigInt.from(5000)));
      expect(transaction.sourceAccountId, equals(accId));

      // Проверяем связь (JOIN)
      // Хотим убедиться, что транзакция реально связана с категорией "Food"
      final query = db.select(db.transactions).join([
        drift.leftOuterJoin(
          db.categories,
          db.categories.id.equalsExp(db.transactions.categoryId),
        ),
      ]);

      final resultRow = await query.getSingle();
      final category = resultRow.readTable(db.categories);

      expect(category.name, equals('Food'));

      print('✅ Test Passed: Transaction linked correctly');
    },
  );
}
