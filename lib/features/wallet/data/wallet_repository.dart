import 'package:drift/drift.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import 'tables/wallet_tables.dart';

class WalletRepository {
  final AppDatabase _db;

  WalletRepository(this._db);

  // Стримим список всех счетов (авто-обновление UI)
  Stream<List<Account>> watchAllAccounts() {
    return (_db.select(_db.accounts)..orderBy([
          (t) => OrderingTerm(expression: t.isMain, mode: OrderingMode.desc),
          (t) => OrderingTerm(expression: t.name),
        ]))
        .watch();
  }

  // Создание
  Future<void> createAccount(AccountsCompanion account) {
    return _db.transaction(() async {
      // Если новый счет должен быть основным -> сбрасываем флаг у всех остальных
      if (account.isMain.present && account.isMain.value == true) {
        await (_db.update(_db.accounts)..where((t) => t.isMain.equals(true)))
            .write(const AccountsCompanion(isMain: Value(false)));
      }
      // Вставляем новый
      await _db.into(_db.accounts).insert(account);
    });
  }

  // Обновить счет (с логикой единственного Main)
  Future<void> updateAccount(Account account) {
    return _db.transaction(() async {
      // Если мы делаем этот счет основным -> сбрасываем остальных
      if (account.isMain) {
        await (_db.update(_db.accounts)
              ..where((t) => t.id.isNotValue(account.id)))
            .write(const AccountsCompanion(isMain: Value(false)));
      }
      // Обновляем текущий
      await _db.update(_db.accounts).replace(account);
    });
  }

  // Удаление
  Future<int> deleteAccount(String id) {
    return (_db.delete(_db.accounts)..where((t) => t.id.equals(id))).go();
  }

  // --- КАТЕГОРИИ ---

  Stream<List<Category>> watchAllCategories() {
    return (_db.select(
      _db.categories,
    )..orderBy([(t) => OrderingTerm(expression: t.name)])).watch();
  }

  // --- ТРАНЗАКЦИИ ---

  Future<void> createTransaction({
    required TransactionsCompanion transaction,
    required List<TransactionItemsCompanion> items,
  }) async {
    return _db.transaction(() async {
      // 1. Сохраняем саму транзакцию
      await _db.into(_db.transactions).insert(transaction);

      // 2. Сохраняем позиции чека (если есть)
      for (var item in items) {
        await _db.into(_db.transactionItems).insert(item);
      }
    });
  }

  // Создать категорию
  Future<void> createCategory(CategoriesCompanion category) {
    return _db.into(_db.categories).insert(category);
  }

  // Обновить категорию
  Future<void> updateCategory(Category category) {
    return _db.update(_db.categories).replace(category);
  }

  // Удалить категорию (теги удалятся каскадно, если настроено в БД)
  Future<void> deleteCategory(String id) {
    return (_db.delete(_db.categories)..where((t) => t.id.equals(id))).go();
  }

  // --- ТЕГИ ---

  // Сохранить список тегов для категории (удаляет старые, пишет новые)
  Future<void> updateTags(String categoryId, List<String> tagNames) {
    return _db.transaction(() async {
      await (_db.delete(
        _db.tags,
      )..where((t) => t.categoryId.equals(categoryId))).go();

      for (var name in tagNames) {
        await _db
            .into(_db.tags)
            .insert(
              TagsCompanion.insert(
                id: const Uuid().v4(),
                categoryId: drift.Value(categoryId),
                name: name,
              ),
            );
      }
    });
  }

  // Получить теги для категории (Async Future для диалога)
  Future<List<Tag>> getTagsForCategory(String categoryId) {
    return (_db.select(
      _db.tags,
    )..where((t) => t.categoryId.equals(categoryId))).get();
  }

  // Получить поток транзакций с товарами
  Stream<List<TransactionWithItems>> watchTransactionsWithItems() {
    // БЫЛО: final query = select(_db.transactions).join([

    // СТАЛО: (добавляем _db.)
    final query = _db.select(_db.transactions).join([
      leftOuterJoin(
        _db.transactionItems,
        _db.transactionItems.transactionId.equalsExp(_db.transactions.id),
      ),
      leftOuterJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.transactions.categoryId),
      ),
      innerJoin(
        _db.accounts,
        _db.accounts.id.equalsExp(_db.transactions.sourceAccountId),
      ),
    ]);

    return query.watch().map((rows) {
      final grouped = <String, TransactionWithItems>{};

      for (var row in rows) {
        final transaction = row.readTable(_db.transactions);
        final item = row.readTableOrNull(_db.transactionItems);
        final category = row.readTableOrNull(_db.categories);
        final account = row.readTable(_db.accounts);

        if (!grouped.containsKey(transaction.id)) {
          grouped[transaction.id] = TransactionWithItems(
            transaction: transaction,
            category: category,
            account: account,
            items: [],
          );
        }

        if (item != null) {
          grouped[transaction.id]!.items.add(item);
        }
      }

      return grouped.values.toList()
        ..sort((a, b) => b.transaction.date.compareTo(a.transaction.date));
    });
  }
}
