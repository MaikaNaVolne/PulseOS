import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../tables/wallet_tables.dart';

part 'debts_dao.g.dart';

@DriftAccessor(tables: [Debts])
class DebtsDao extends DatabaseAccessor<AppDatabase> with _$DebtsDaoMixin {
  DebtsDao(super.db);

  // Стрим всех активных долгов
  Stream<List<Debt>> watchActiveDebts() {
    return (select(debts)..where((t) => t.isClosed.equals(false))).watch();
  }

  // Стрим истории (закрытых)
  Stream<List<Debt>> watchHistory() {
    return (select(debts)..where((t) => t.isClosed.equals(true))).watch();
  }

  // Создать долг
  Future<void> createDebt(DebtsCompanion debt) {
    return into(debts).insert(debt);
  }

  // Закрыть долг (вернуть)
  Future<void> closeDebt(String id) {
    return (update(debts)..where((t) => t.id.equals(id))).write(
      DebtsCompanion(
        isClosed: const Value(true),
        closedDate: Value(DateTime.now()),
      ),
    );
  }

  // Обновить существующий долг
  Future<void> updateDebt(Debt debt) {
    return update(debts).replace(debt);
  }
}
