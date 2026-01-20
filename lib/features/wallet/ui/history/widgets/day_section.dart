import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/pulse_theme.dart';
import '../../../data/tables/wallet_tables.dart';
import '../../../presentation/wallet_provider.dart';
import '../../transactions/transaction_editor_page.dart';
import 'transaction_tile.dart';

class DaySection extends StatelessWidget {
  final DateTime date;
  final List<TransactionWithItems> transactions; // <--- ИЗМЕНИТЬ ТИП

  const DaySection({super.key, required this.date, required this.transactions});

  @override
  Widget build(BuildContext context) {
    context.watch<WalletProvider>();

    // Считаем итог дня (Расходы с минусом, доходы с плюсом)
    double dayTotal = 0;
    for (var item in transactions) {
      final t = item.transaction; // <--- ДОСТАЕМ ТРАНЗАКЦИЮ
      double amount = t.amount.toDouble() / 100;

      if (t.type == 'expense' || t.type == 'transfer_person') {
        dayTotal -= amount;
      } else if (t.type == 'income') {
        dayTotal += amount;
      }
    }

    final dateStr = DateFormat('d MMMM', 'ru').format(date);
    final dayOfWeek = DateFormat('EEEE', 'ru').format(date).toUpperCase();
    final isToday = DateUtils.isSameDay(date, DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Хедер дня
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    isToday ? "СЕГОДНЯ" : dayOfWeek,
                    style: TextStyle(
                      color: isToday
                          ? PulseColors.primary
                          : Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (!isToday) ...[
                    const SizedBox(width: 8),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
              if (dayTotal != 0)
                Text(
                  "${dayTotal > 0 ? '+' : ''}${dayTotal.toStringAsFixed(0)} ₽",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),

        // Список транзакций
        ...transactions.map((item) {
          return TransactionTile(
            data: item, // item это TransactionWithItems
            onTap: () {
              // ОТКРЫВАЕМ РЕДАКТОР
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TransactionEditorPage(
                    transactionWithItems: item, // Передаем данные
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}
