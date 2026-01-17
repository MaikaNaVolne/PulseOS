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
  Future<void> createAccount(AccountsCompanion account) {
    return _db.transaction(() async {
      // Если новый счет должен быть основным -> сбрасываем флаг у всех остальных
      if (account.isMain.value == true) {
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
}
