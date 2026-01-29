import 'package:drift/drift.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../domain/models/category_stat_dto.dart';
import '../domain/models/transaction_filter.dart';
import 'tables/wallet_tables.dart';

class WalletRepository {
  final AppDatabase _db;

  WalletRepository(this._db);

  Stream<List<Account>> watchAllAccounts() {
    return (_db.select(_db.accounts)..orderBy([
          (t) => OrderingTerm(expression: t.isMain, mode: OrderingMode.desc),
          (t) => OrderingTerm(expression: t.name),
        ]))
        .watch();
  }

  Future<void> createAccount(AccountsCompanion account) {
    return _db.transaction(() async {
      if (account.isMain.present && account.isMain.value == true) {
        await (_db.update(_db.accounts)..where((t) => t.isMain.equals(true)))
            .write(const AccountsCompanion(isMain: Value(false)));
      }
      await _db.into(_db.accounts).insert(account);
    });
  }

  Future<void> updateAccount(Account account) {
    return _db.transaction(() async {
      if (account.isMain) {
        await (_db.update(_db.accounts)
              ..where((t) => t.id.isNotValue(account.id)))
            .write(const AccountsCompanion(isMain: Value(false)));
      }
      await _db.update(_db.accounts).replace(account);
    });
  }

  Future<int> deleteAccount(String id) {
    return (_db.delete(_db.accounts)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<Category>> watchAllCategories() {
    return (_db.select(
      _db.categories,
    )..orderBy([(t) => OrderingTerm(expression: t.name)])).watch();
  }

  // ОБНОВЛЕННЫЙ МЕТОД (Upsert транзакции)
  Future<void> createTransaction({
    required TransactionsCompanion transaction,
    required List<TransactionItemsCompanion> items,
  }) async {
    return _db.transaction(() async {
      // Очищаем старые позиции, если мы редактируем существующую транзакцию
      await (_db.delete(
        _db.transactionItems,
      )..where((t) => t.transactionId.equals(transaction.id.value))).go();

      // Обновляем или вставляем саму транзакцию
      await _db.into(_db.transactions).insertOnConflictUpdate(transaction);

      // Вставляем позиции заново
      for (var item in items) {
        await _db.into(_db.transactionItems).insert(item);
      }
    });
  }

  Future<void> createCategory(CategoriesCompanion category) {
    return _db.into(_db.categories).insert(category);
  }

  Future<void> updateCategory(Category category) {
    return _db.update(_db.categories).replace(category);
  }

  Future<void> deleteCategory(String id) {
    return (_db.delete(_db.categories)..where((t) => t.id.equals(id))).go();
  }

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

  Future<List<Tag>> getTagsForCategory(String categoryId) {
    return (_db.select(
      _db.tags,
    )..where((t) => t.categoryId.equals(categoryId))).get();
  }

  Stream<List<TransactionWithItems>> watchTransactionsWithItems({
    TransactionFilter? filter,
  }) {
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

    if (filter != null) {
      if (filter.type != null)
        query.where(_db.transactions.type.equals(filter.type!.dbValue));
      if (filter.accountId != null)
        query.where(_db.transactions.sourceAccountId.equals(filter.accountId!));
      if (filter.categoryIds.isNotEmpty)
        query.where(_db.transactions.categoryId.isIn(filter.categoryIds));
      if (filter.startDate != null)
        query.where(
          _db.transactions.date.isBiggerOrEqualValue(filter.startDate!),
        );
      if (filter.endDate != null)
        query.where(
          _db.transactions.date.isSmallerOrEqualValue(filter.endDate!),
        );
    }

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
        if (item != null) grouped[transaction.id]!.items.add(item);
      }
      return grouped.values.toList()
        ..sort((a, b) => b.transaction.date.compareTo(a.transaction.date));
    });
  }

  // АНАЛИТИКА И ОТЧЕТЫ

  /// 1. Получить общую сводку (Доход / Расход) за период
  Future<Map<String, double>> getPeriodSummary({
    required DateTime start,
    required DateTime end,
  }) async {
    // Выбираем только расходы и доходы (без переводов)
    final query = _db.select(_db.transactions)
      ..where((t) => t.date.isBiggerOrEqualValue(start))
      ..where((t) => t.date.isSmallerOrEqualValue(end))
      ..where((t) => t.type.isIn(['income', 'expense']));

    final transactions = await query.get();

    double income = 0;
    double expense = 0;

    for (var t in transactions) {
      final amount = t.amount.toDouble() / 100; // Конвертация копеек
      if (t.type == 'income') {
        income += amount;
      } else {
        expense += amount;
      }
    }

    return {'income': income, 'expense': expense};
  }

  /// 2. Получить список трат, сгруппированный по категориям (для Графика)
  Stream<List<CategoryStatDto>> watchCategoryStats({
    required DateTime start,
    required DateTime end,
    required String type, // 'expense' или 'income'
  }) {
    // Нам нужно: Сумма amount, Категория
    final amountSum = _db.transactions.amount.sum();
    final countId = _db.transactions.id.count();

    final query = _db.select(_db.transactions).join([
      leftOuterJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.transactions.categoryId),
      ),
    ]);

    // Фильтры
    query.where(_db.transactions.date.isBiggerOrEqualValue(start));
    query.where(_db.transactions.date.isSmallerOrEqualValue(end));
    query.where(_db.transactions.type.equals(type));

    // Группировка по ID категории
    query.groupBy([_db.transactions.categoryId]);

    // Сортировка по сумме (от больших к меньшим)
    query.orderBy([
      OrderingTerm(expression: amountSum, mode: OrderingMode.desc),
    ]);

    // Добавляем вычисляемые колонки
    query.addColumns([amountSum, countId]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final category = row.readTableOrNull(_db.categories);
        final totalCents =
            row.read(amountSum) ?? BigInt.zero; // Сумма может быть null
        final count = row.read(countId) ?? 0;

        return CategoryStatDto(
          category: category,
          totalAmount: totalCents.toDouble() / 100, // В рубли
          transactionCount: count,
        );
      }).toList();
    });
  }
}
