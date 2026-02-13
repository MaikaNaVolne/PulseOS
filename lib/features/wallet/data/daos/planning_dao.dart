import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../tables/wallet_tables.dart';

part 'planning_dao.g.dart';

@DriftAccessor(tables: [PlannedTransactions])
class PlanningDao extends DatabaseAccessor<AppDatabase>
    with _$PlanningDaoMixin {
  PlanningDao(super.db);

  // Класс PlannedTransaction (ед. число) генерируется Drift автоматически
  Stream<List<PlannedTransaction>> watchAllPlanned() {
    return (select(plannedTransactions)..orderBy([
          (t) => OrderingTerm(expression: t.date, mode: OrderingMode.asc),
        ]))
        .watch();
  }

  Future<void> createPlanned(PlannedTransactionsCompanion entry) {
    return into(plannedTransactions).insert(entry);
  }

  Future<void> completePlanned(String id, bool completed) {
    return (update(plannedTransactions)..where((t) => t.id.equals(id))).write(
      PlannedTransactionsCompanion(isCompleted: Value(completed)),
    );
  }

  Future<void> deletePlanned(String id) {
    return (delete(plannedTransactions)..where((t) => t.id.equals(id))).go();
  }
}
