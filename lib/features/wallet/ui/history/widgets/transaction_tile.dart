import 'package:flutter/material.dart';
import '../../../../../core/theme/pulse_theme.dart';
import '../../../../../core/utils/icon_helper.dart';
import '../../../data/tables/wallet_tables.dart';
import '../../transactions/utils/transaction_types.dart'; // Наш Enum

class TransactionTile extends StatelessWidget {
  final TransactionWithItems data; // DTO
  final VoidCallback onTap;

  const TransactionTile({super.key, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final transaction = data.transaction; // Сама транзакция
    final category = data.category;
    final account = data.account;
    final items = data.items;

    // 1. Определяем тип (через Enum)
    final typeEnum = _getTypeEnum(transaction.type);

    // 2. Логика цвета и знака
    final isIncome =
        typeEnum == TransactionType.income ||
        typeEnum == TransactionType.transferPerson;
    final amountColor = isIncome ? PulseColors.green : Colors.white;
    final sign = isIncome ? '+' : '-';

    // 3. Иконка и цвет
    IconData icon;
    Color color;

    if (typeEnum == TransactionType.transfer) {
      icon = Icons.swap_horiz;
      color = PulseColors.blue;
    } else if (category != null) {
      icon = getIcon(category.iconKey ?? 'category');
      color = _hexToColor(category.colorHex);
    } else {
      icon = Icons.receipt_long;
      color = Colors.grey;
    }

    // 4. Заголовок (Магазин / Заметка / Товар)
    // Используем поля из БД: shopName и note
    String title = transaction.shopName ?? transaction.note ?? "Без названия";

    // Если магазина нет, но есть товары -> берем первый товар
    if ((transaction.shopName == null || transaction.shopName!.isEmpty) &&
        items.isNotEmpty) {
      title = items.first.name;
      if (items.length > 1) {
        title += " (+${items.length - 1})";
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Иконка
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),

            // Текст
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      // Категория (если есть)
                      if (category != null) ...[
                        Text(
                          category.name,
                          style: TextStyle(
                            color: color.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        _dotSeparator(),
                      ],
                      // Счет
                      Text(
                        account?.name ?? "Счет",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Сумма
            Text(
              "$sign${(transaction.amount / BigInt.from(100)).toStringAsFixed(0)} ₽",
              style: TextStyle(
                color: amountColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dotSeparator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
    );
  }

  TransactionType _getTypeEnum(String dbValue) {
    return TransactionType.values.firstWhere(
      (e) => e.dbValue == dbValue,
      orElse: () => TransactionType.expense,
    );
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.grey;
    }
  }
}
