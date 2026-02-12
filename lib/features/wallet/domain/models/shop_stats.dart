// lib/features/wallet/domain/models/shop_stats.dart
class ShopStats {
  final String name;
  final int visits;
  final double totalSpent; // В рублях
  final DateTime lastVisit;

  ShopStats({
    required this.name,
    required this.visits,
    required this.totalSpent,
    required this.lastVisit,
  });
}
