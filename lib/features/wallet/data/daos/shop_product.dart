class ShopProduct {
  final String name;
  final double lastPrice;
  final int buyCount;
  final bool hasPriceChanged;

  ShopProduct({
    required this.name,
    required this.lastPrice,
    required this.buyCount,
    required this.hasPriceChanged,
  });
}
