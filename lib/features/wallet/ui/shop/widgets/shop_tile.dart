import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/pulse_theme.dart';
import '../../../domain/models/shop_stats.dart';

class ShopTile extends StatelessWidget {
  final ShopStats shop;
  final VoidCallback onTap;

  const ShopTile({super.key, required this.shop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Форматируем сумму (1 250 ₽)
    final currencyFmt = NumberFormat("#,##0", "ru_RU");
    // Форматируем дату (25 окт)
    final dateFmt = DateFormat('d MMM', 'ru');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Очень легкий прозрачный фон для эффекта глубины
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            // 1. ИКОНКА (В стиле модуля Магазины)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PulseColors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: PulseColors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),

            // 2. ИНФОРМАЦИЯ (Название и доп. стат)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${shop.visits} визитов • ${dateFmt.format(shop.lastVisit)}",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // 3. СУММА
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${currencyFmt.format(shop.totalSpent)} ₽",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                // Иконка-стрелочка
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.15),
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
