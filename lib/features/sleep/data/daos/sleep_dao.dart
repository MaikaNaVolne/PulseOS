import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../tables/sleep_tables.dart';
import 'package:uuid/uuid.dart';

part 'sleep_dao.g.dart';

@DriftAccessor(
  tables: [SleepEntries, SleepFactors, SleepFactorLinks, SleepGoals],
)
class SleepDao extends DatabaseAccessor<AppDatabase> with _$SleepDaoMixin {
  SleepDao(super.db);

  // Получить все записи сна (новые сверху)
  Stream<List<SleepEntry>> watchAllSleep() {
    return (select(sleepEntries)..orderBy([
          (t) => OrderingTerm(expression: t.endTime, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  // Создать запись о сне
  Future<void> insertSleep(SleepEntriesCompanion entry) =>
      into(sleepEntries).insert(entry);

  // Привязать факторы к записи сна
  Future<void> linkFactorToSleep(String sleepId, String factorId) {
    return into(sleepFactorLinks).insert(
      SleepFactorLinksCompanion.insert(
        id: const Uuid().v4(),
        sleepId: sleepId,
        factorId: factorId,
      ),
    );
  }

  // Получить список факторов для конкретного сна (удобно для UI)
  Future<List<SleepFactor>> getFactorsForSleep(String sleepId) async {
    final query = select(sleepFactors).join([
      innerJoin(
        sleepFactorLinks,
        sleepFactorLinks.factorId.equalsExp(sleepFactors.id),
      ),
    ])..where(sleepFactorLinks.sleepId.equals(sleepId));

    final rows = await query.get();
    return rows.map((row) => row.readTable(sleepFactors)).toList();
  }

  // Получить все факторы из справочника
  Future<List<SleepFactor>> getAllFactors() => select(sleepFactors).get();

  // Удалить старые связи (для редактирования)
  Future<void> clearFactorLinks(String sleepId) {
    return (delete(
      sleepFactorLinks,
    )..where((t) => t.sleepId.equals(sleepId))).go();
  }

  // Получить цели (всегда берем первую запись)
  Future<SleepGoal?> getGoals() => select(sleepGoals).getSingleOrNull();

  Future<void> updateGoals(SleepGoalsCompanion entry) =>
      into(sleepGoals).insertOnConflictUpdate(entry);
}
