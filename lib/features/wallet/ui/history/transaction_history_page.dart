import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/ui_kit/pulse_page.dart';
import '../../../../core/ui_kit/pulse_buttons.dart';
import '../../../../core/theme/pulse_theme.dart';
import '../../presentation/wallet_provider.dart';
import 'widgets/day_section.dart';
import 'widgets/filter_sheet.dart';

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Получаем список транзакций (DTO)
    final wallet = context.watch<WalletProvider>();
    final transactions = wallet.transactions;

    // 2. Группируем по ДНЮ (игнорируя время)
    final grouped = groupBy(transactions, (item) {
      final date = item.transaction.date;
      return DateTime(date.year, date.month, date.day);
    });

    // 3. Сортируем дни (от новых к старым)
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return PulsePage(
      title: "История",
      subtitle: "ОПЕРАЦИИ",
      accentColor: PulseColors.primary,
      showBackButton: true,

      actions: [
        GlassCircleButton(
          icon: Icons.tune,
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => const FilterSheet(),
            );
          },
        ),
      ],
      body: sortedDates.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 100),
                child: Column(
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.white10),
                    SizedBox(height: 20),
                    Text(
                      "История пуста",
                      style: TextStyle(color: Colors.white24),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: sortedDates.map((date) {
                final dayTrans = grouped[date]!;
                // Сортируем внутри дня (новые сверху)
                dayTrans.sort(
                  (a, b) => b.transaction.date.compareTo(a.transaction.date),
                );

                return DaySection(date: date, transactions: dayTrans);
              }).toList(),
            ),
    );
  }
}
