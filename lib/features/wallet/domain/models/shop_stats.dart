// 1. Общая статистика магазина (для списка магазинов)
class ShopStats {
  final String name;
  final int visits;
  final double totalSpent;
  final DateTime lastVisit;

  ShopStats({
    required this.name,
    required this.visits,
    required this.totalSpent,
    required this.lastVisit,
  });
}

// 2. Статистика конкретного товара в магазине (детектор шринкфляции)
class ShopProduct {
  final String name;
  final double normalizedPrice; // Цена за 100г / 1 шт
  final String unitLabel; // Например: "за 100 г"
  final int buyCount;
  final bool hasPriceChanged;

  ShopProduct({
    required this.name,
    required this.normalizedPrice,
    required this.unitLabel,
    required this.buyCount,
    required this.hasPriceChanged,
  });
}

// 3. Точка на графике цен
class PricePoint {
  final DateTime date;
  final double price;

  PricePoint(this.date, this.price);
}
