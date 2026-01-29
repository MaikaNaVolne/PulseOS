import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/pulse_theme.dart';
import '../../../../../core/ui_kit/pulse_page.dart';
import '../../../presentation/wallet_provider.dart';
import '../../history/widgets/transaction_tile.dart';

class WalletCategoryReportDetailsPage extends StatelessWidget {
  final String? categoryId;
  final String categoryName;
  final DateTime start;
  final DateTime end;

  const WalletCategoryReportDetailsPage({
    super.key,
    this.categoryId,
    required this.categoryName,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    // 1. Фильтруем транзакции по категории и дате
    final filteredTrans = wallet.transactions.where((t) {
      final isSameCat = t.transaction.categoryId == categoryId;
      final isInPeriod =
          t.transaction.date.isAfter(
            start.subtract(const Duration(seconds: 1)),
          ) &&
          t.transaction.date.isBefore(end);
      return isSameCat && isInPeriod;
    }).toList();

    final totalAmount = filteredTrans.fold(
      0.0,
      (sum, t) => sum + (t.transaction.amount.toDouble() / 100),
    );

    // 2. Группируем товары по названию (Топ продуктов)
    final Map<String, double> productSums = {};
    for (var t in filteredTrans) {
      for (var item in t.items) {
        productSums.update(
          item.name,
          (val) => val + (item.price.toDouble() / 100 * item.quantity),
          ifAbsent: () => (item.price.toDouble() / 100 * item.quantity),
        );
      }
    }

    final sortedProducts = productSums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return PulsePage(
      title: categoryName,
      subtitle: "ДЕТАЛИЗАЦИЯ",
      accentColor: PulseColors.primary,
      showBackButton: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Сводка сверху
          _buildSummaryHeader(totalAmount, filteredTrans.length),

          const SizedBox(height: 32),

          // Секция ТОП ТОВАРОВ (если есть)
          if (sortedProducts.isNotEmpty) ...[
            _buildSectionTitle("ТОП ПОЗИЦИЙ"),
            const SizedBox(height: 12),
            _buildTopProductsList(sortedProducts),
            const SizedBox(height: 32),
          ],

          // СПИСОК ОПЕРАЦИЙ
          _buildSectionTitle("ОПЕРАЦИИ"),
          const SizedBox(height: 12),
          ...filteredTrans.map((t) => TransactionTile(data: t, onTap: () {})),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(double total, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PulseColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PulseColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            "${total.toInt()} ₽",
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            "$count транзакций в этот период",
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTopProductsList(List<MapEntry<String, double>> products) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: products
            .take(5)
            .map(
              (p) => ListTile(
                title: Text(
                  p.key,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                trailing: Text(
                  "${p.value.toInt()} ₽",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
