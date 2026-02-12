import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/models/shop_stats.dart';
import '../tables/wallet_tables.dart'; // Импорт таблиц

part 'shops_dao.g.dart'; // Этот файл сгенерируется

@DriftAccessor(tables: [Transactions])
class ShopsDao extends DatabaseAccessor<AppDatabase> with _$ShopsDaoMixin {
  ShopsDao(super.db);

  /// Получить список магазинов с агрегированной статистикой
  Stream<List<ShopStats>> watchShops() {
    // Определяем алиасы для колонок агрегации
    final visits = transactions.id.count();
    final total = transactions.amount.sum();
    final lastVisit = transactions.date.max();

    final query = selectOnly(transactions)
      ..addColumns([transactions.shopName, visits, total, lastVisit])
      // Фильтруем пустые названия и расходы
      ..where(transactions.shopName.isNotNull())
      ..where(transactions.type.equals('expense'))
      ..groupBy([transactions.shopName])
      // Сортируем: сначала самые посещаемые
      ..orderBy([OrderingTerm(expression: visits, mode: OrderingMode.desc)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final totalCents = row.read(total) ?? BigInt.zero;

        return ShopStats(
          name: row.read(transactions.shopName) ?? 'Неизвестно',
          visits: row.read(visits) ?? 0,
          totalSpent: totalCents.toDouble() / 100.0,
          lastVisit: row.read(lastVisit) ?? DateTime.now(),
        );
      }).toList();
    });
  }
}
