import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/models/price_point.dart';
import '../../domain/models/shop_stats.dart';
import '../tables/wallet_tables.dart';
import 'shop_product.dart'; // Импорт таблиц

part 'shops_dao.g.dart'; // Этот файл сгенерируется

@DriftAccessor(tables: [Transactions, TransactionItems])
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

  Stream<List<ShopProduct>> watchProductsInShop(String shopName) {
    // Создаем запрос с JOIN
    final query = select(transactionItems).join([
      innerJoin(
        transactions,
        transactions.id.equalsExp(transactionItems.transactionId),
      ),
    ]);

    // Фильтруем по имени магазина
    query.where(transactions.shopName.equals(shopName));

    return query.watch().map((rows) {
      // Группируем результат по названию товара вручную для более гибкой логики цен
      final grouped = <String, List<double>>{};

      for (final row in rows) {
        final item = row.readTable(transactionItems);
        final name = item.name.trim();
        final price = item.price.toDouble() / 100.0;

        grouped.putIfAbsent(name, () => []).add(price);
      }

      return grouped.entries.map((e) {
        final prices = e.value;
        return ShopProduct(
          name: e.key,
          lastPrice: prices.last, // Drift вернет в порядке добавления
          buyCount: prices.length,
          hasPriceChanged: prices.toSet().length > 1,
        );
      }).toList()..sort(
        (a, b) => b.buyCount.compareTo(a.buyCount),
      ); // Самые частые сверху
    });
  }

  Stream<List<PricePoint>> watchProductPriceHistory(
    String shopName,
    String productName,
  ) {
    final query = select(transactionItems).join([
      innerJoin(
        transactions,
        transactions.id.equalsExp(transactionItems.transactionId),
      ),
    ]);

    query.where(transactions.shopName.equals(shopName));
    query.where(transactionItems.name.equals(productName));

    // Сортировка для корректного отображения на графике (слева направо)
    query.orderBy([
      OrderingTerm(expression: transactions.date, mode: OrderingMode.asc),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final item = row.readTable(transactionItems);
        final tx = row.readTable(transactions);
        return PricePoint(tx.date, item.price.toDouble() / 100.0);
      }).toList();
    });
  }
}
