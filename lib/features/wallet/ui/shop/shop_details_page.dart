import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/pulse_theme.dart';
import '../../../../core/ui_kit/pulse_page.dart';
import '../../data/daos/shop_product.dart';
import 'widgets/price_history_sheet.dart';

class ShopDetailsPage extends StatelessWidget {
  final String shopName;

  const ShopDetailsPage({super.key, required this.shopName});

  @override
  Widget build(BuildContext context) {
    return PulsePage(
      title: shopName,
      subtitle: "ИСТОРИЯ ТОВАРОВ",
      accentColor: PulseColors.orange,
      showBackButton: true,
      body: StreamBuilder<List<ShopProduct>>(
        // Используем наш DAO для реактивного обновления списка
        stream: sl<AppDatabase>().shopsDao.watchProductsInShop(shopName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 100),
                child: CircularProgressIndicator(color: PulseColors.orange),
              ),
            );
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 16),
                child: Text(
                  "НАЖМИТЕ НА ТОВАР ДЛЯ ГРАФИКА ЦЕН",
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              // Разворачиваем список плиток
              ...products.map(
                (product) => _ProductTile(product: product, shopName: shopName),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Column(
          children: [
            Icon(
              Icons.shopping_basket_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.05),
            ),
            const SizedBox(height: 16),
            const Text(
              "В этом магазине еще нет товаров",
              style: TextStyle(color: Colors.white24),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final ShopProduct product;
  final String shopName;

  const _ProductTile({required this.product, required this.shopName});

  void _showPriceHistory(BuildContext context) {
    // Виброотклик для приятного UX
    HapticFeedback.lightImpact();

    // Открываем шторку с графиком цен
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Позволяет шторке подстраиваться под контент
      builder: (_) =>
          PriceHistorySheet(shopName: shopName, productName: product.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPriceHistory(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            // Индикатор изменения цены (Trending)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    (product.hasPriceChanged
                            ? PulseColors.orange
                            : Colors.white)
                        .withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                product.hasPriceChanged
                    ? Icons.trending_up
                    : Icons.horizontal_rule,
                color: product.hasPriceChanged
                    ? PulseColors.orange
                    : Colors.white24,
                size: 18,
              ),
            ),
            const SizedBox(width: 16),

            // Название товара
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${product.buyCount} покупок",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Цена
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${product.lastPrice.toStringAsFixed(0)} ₽",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                if (product.hasPriceChanged)
                  const Text(
                    "цена менялась",
                    style: TextStyle(
                      color: PulseColors.orange,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.1),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
