import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../../core/utils/icon_helper.dart';
import '../../../domain/models/category_stat_dto.dart';
import '../../../presentation/wallet_provider.dart';
import 'wallet_category_report_details_page.dart';

class CategoryStatList extends StatelessWidget {
  final List<CategoryStatDto> stats;

  const CategoryStatList({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();

    return Column(
      children: stats.map((item) {
        final color = _hexToColor(item.category?.colorHex ?? '#808080');
        final percentage = (item.percentage * 100).toStringAsFixed(1);

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            final provider = context.read<WalletProvider>();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WalletCategoryReportDetailsPage(
                  categoryId: item.category?.id,
                  categoryName: item.category?.name ?? "Без категории",
                  start: provider.reportStartDate,
                  end: provider.reportEndDate,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Иконка категории
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        getIcon(item.category?.iconKey ?? 'category'),
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Название и кол-во операций
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.category?.name ?? "Без категории",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "${item.transactionCount} операций",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Сумма и %
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${item.totalAmount.toInt()} ₽",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "$percentage%",
                          style: TextStyle(
                            color: color.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Прогресс-бар доли категории
                Stack(
                  children: [
                    Container(
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: item.percentage.clamp(0.0, 1.0),
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withValues(alpha: 0.5)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
