import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:pulseos/core/database/app_database.dart';
import 'package:pulseos/features/wallet/data/wallet_repository.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;
  late WalletRepository repo;
  final uuid = const Uuid();

  setUp(() {
    // Чистая база в памяти
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = WalletRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('Полный цикл транзакции: Счет -> Транзакция -> История', () async {
    // 1. Создаем счет
    final accId = uuid.v4();
    await repo.createAccount(
      AccountsCompanion.insert(
        id: accId,
        name: 'Test Card',
        type: 'card',
        currencyCode: 'RUB',
        balance: drift.Value(BigInt.from(100000)), // 1000.00
      ),
    );

    // 2. Создаем категорию (опционально, но проверим связь)
    final catId = uuid.v4();
    await repo.createCategory(
      CategoriesCompanion.insert(id: catId, name: 'Еда', colorHex: '#00FF00'),
    );

    // 3. Создаем транзакцию с товаром
    final transId = uuid.v4();

    // Эмулируем данные из провайдера
    final transaction = TransactionsCompanion.insert(
      id: transId,
      type: 'expense',
      sourceAccountId: accId,
      categoryId: drift.Value(catId),
      amount: BigInt.from(5000), // 50.00
      date: DateTime.now(),
      shopName: drift.Value('Пятерочка'),
    );

    final item = TransactionItemsCompanion.insert(
      id: uuid.v4(),
      transactionId: transId,
      name: 'Молоко',
      price: BigInt.from(5000),
      quantity: drift.Value(1.0),
    );

    await repo.createTransaction(transaction: transaction, items: [item]);

    // 4. ПРОВЕРЯЕМ: Читаем через сложный запрос (тот, что не работает в UI)
    // Используем take(1) потому что это Stream
    final history = await repo.watchTransactionsWithItems().first;

    print("Найдено записей в истории: ${history.length}");

    expect(history.length, 1, reason: "Транзакция должна вернуться в истории");

    final t = history.first;
    expect(t.transaction.shopName, 'Пятерочка');
    expect(t.items.length, 1);
    expect(t.items.first.name, 'Молоко');
    expect(t.account?.name, 'Test Card');
    expect(t.category?.name, 'Еда');

    print("✅ Тест успешно пройден!");
  });
}
