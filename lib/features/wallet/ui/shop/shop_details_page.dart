import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/pulse_theme.dart';
import '../../../../core/ui_kit/pulse_page.dart';
import '../../data/daos/shop_product.dart';

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
        // Передаем shopName в наш DAO
        stream: sl<AppDatabase>().shopsDao.watchProductsInShop(shopName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: PulseColors.orange),
            );
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(
              child: Text(
                "В этом магазине еще нет купленных товаров",
                style: TextStyle(color: Colors.white24),
              ),
            );
          }

          return Column(
            children: products
                .map((product) => _ProductTile(product: product))
                .toList(),
          );
        },
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final ShopProduct product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(
            product.hasPriceChanged ? Icons.trending_up : Icons.horizontal_rule,
            color: product.hasPriceChanged
                ? PulseColors.orange
                : Colors.white24,
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              product.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${product.lastPrice.toStringAsFixed(0)} ₽",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                "${product.buyCount} покупок",
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
