import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';

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
  Future<int> createAccount(AccountsCompanion account) {
    return _db.into(_db.accounts).insert(account);
  }

  // Обновление (replace ищет по ID и заменяет все поля)
  Future<bool> updateAccount(Account account) {
    return _db.update(_db.accounts).replace(account);
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
}
