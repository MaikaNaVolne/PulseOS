// lib/features/wallet/data/daos/shops_dao.dart
import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';

// ИМПОРТИРУЕМ ЕДИНЫЙ ФАЙЛ С МОДЕЛЯМИ
import '../../domain/models/shop_stats.dart';
import '../tables/wallet_tables.dart';

part 'shops_dao.g.dart';

@DriftAccessor(tables: [Transactions, TransactionItems])
class ShopsDao extends DatabaseAccessor<AppDatabase> with _$ShopsDaoMixin {
  ShopsDao(super.db);

  /// 1. Получить список магазинов с агрегированной статистикой
  Stream<List<ShopStats>> watchShops() {
    final visits = transactions.id.count();
    final total = transactions.amount.sum();
    final lastVisit = transactions.date.max();

    final query = selectOnly(transactions)
      ..addColumns([transactions.shopName, visits, total, lastVisit])
      ..where(transactions.shopName.isNotNull())
      ..where(transactions.type.equals('expense'))
      ..groupBy([transactions.shopName])
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

  /// 2. Получить список товаров в конкретном магазине
  Stream<List<ShopProduct>> watchProductsInShop(String shopName) {
    final query = select(transactionItems).join([
      innerJoin(
        transactions,
        transactions.id.equalsExp(transactionItems.transactionId),
      ),
    ]);

    query.where(transactions.shopName.equals(shopName));

    return query.watch().map((rows) {
      final grouped = <String, List<Map<String, dynamic>>>{};

      for (final row in rows) {
        final item = row.readTable(transactionItems);
        final name = item.name.trim();
        final rawPrice = item.price.toDouble() / 100.0;

        double normalizedPrice = rawPrice;
        String label = "за шт";

        if (item.unitAmount != null && item.unitAmount! > 0) {
          if (item.unitName == 'g' || item.unitName == 'ml') {
            normalizedPrice = rawPrice / (item.unitAmount! / 100.0);
            label = item.unitName == 'g' ? "за 100 г" : "за 100 мл";
          } else {
            normalizedPrice = rawPrice / item.unitAmount!;
            label = "за 1 ${item.unitName ?? 'шт'}";
          }
        }

        grouped.putIfAbsent(name, () => []).add({
          'price': normalizedPrice,
          'label': label,
        });
      }

      return grouped.entries.map((e) {
        final prices = e.value.map((m) => m['price'] as double).toList();
        final label = e.value.last['label'] as String;

        return ShopProduct(
          name: e.key,
          normalizedPrice: prices.last,
          unitLabel: label,
          buyCount: prices.length,
          hasPriceChanged: prices.toSet().length > 1,
        );
      }).toList()..sort((a, b) => b.buyCount.compareTo(a.buyCount));
    });
  }

  /// 3. История цены на один конкретный товар в магазине
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
    query.orderBy([
      OrderingTerm(expression: transactions.date, mode: OrderingMode.asc),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final item = row.readTable(transactionItems);
        final tx = row.readTable(transactions);

        final rawPrice = item.price.toDouble() / 100.0;
        double normalizedPrice = rawPrice;

        if (item.unitAmount != null && item.unitAmount! > 0) {
          if (item.unitName == 'g' || item.unitName == 'ml') {
            normalizedPrice = rawPrice / (item.unitAmount! / 100.0);
          } else {
            normalizedPrice = rawPrice / item.unitAmount!;
          }
        }

        return PricePoint(tx.date, normalizedPrice);
      }).toList();
    });
  }
}
