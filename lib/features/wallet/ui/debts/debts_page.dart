// lib/features/wallet/ui/debts/debts_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/pulse_theme.dart';
import '../../../../core/ui_kit/pulse_page.dart';
import '../../domain/logic/debt_calculator.dart';
import 'dialogs/add_debt_dialog.dart';
import 'dialogs/repay_debt_dialog.dart';

class DebtsPage extends StatelessWidget {
  const DebtsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PulsePage(
      title: "Долги",
      subtitle: "ОБЯЗАТЕЛЬСТВА",
      accentColor: PulseColors.red,
      showBackButton: true,

      // Плавающая кнопка (FAB)
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDebtDialog(context),
        backgroundColor: PulseColors.red,
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: StreamBuilder<List<Debt>>(
        stream: sl<AppDatabase>().debtsDao.watchActiveDebts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: PulseColors.red),
            );
          }

          final debts = snapshot.data!;

          // Считаем итоги
          double oweMe = 0;
          double iOwe = 0;

          for (var d in debts) {
            final currentAmount = DebtCalculator.calculateCurrentAmount(d);
            if (d.isOweMe) {
              oweMe += currentAmount;
            } else {
              iOwe += currentAmount;
            }
          }

          return Column(
            children: [
              // 1. Карточки итогов
              _buildSummaryCards(oweMe, iOwe),

              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "АКТИВНЫЕ",
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),

              // 2. Список долгов
              if (debts.isEmpty)
                _buildEmptyState()
              else
                ...debts.map((d) => _DebtTile(debt: d)),

              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(double oweMe, double iOwe) {
    final fmt = NumberFormat("#,##0", "ru_RU");
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: "МНЕ ДОЛЖНЫ",
            value: "${fmt.format(oweMe)} ₽",
            color: PulseColors.green,
            icon: Icons.arrow_downward,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: "Я ДОЛЖЕН",
            value: "${fmt.format(iOwe)} ₽",
            color: PulseColors.red,
            icon: Icons.arrow_upward,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 40),
        child: Text(
          "Долгов нет. И это прекрасно!",
          style: TextStyle(color: Colors.white24),
        ),
      ),
    );
  }

  void _showAddDebtDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const AddDebtDialog());
  }
}

// Карточка сводки (Summary)
class _SummaryCard extends StatelessWidget {
  final String title, value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Плитка долга (Tile)
class _DebtTile extends StatelessWidget {
  final Debt debt;
  const _DebtTile({required this.debt});

  @override
  @override
  Widget build(BuildContext context) {
    // Расчет текущей суммы (с процентами и штрафами)
    final currentAmount = DebtCalculator.calculateCurrentAmount(debt);
    final fmt = NumberFormat("#,##0", "ru_RU");
    final color = debt.isOweMe ? PulseColors.green : PulseColors.red;

    // Считаем дни до дедлайна или просрочку
    String timeStatus = "Бессрочно";
    Color timeColor = Colors.white24;

    if (debt.dueDate != null) {
      final diff = debt.dueDate!.difference(DateTime.now()).inDays;
      if (diff < 0) {
        timeStatus = "Просрочено на ${diff.abs()} дн.";
        timeColor = PulseColors.red;
      } else if (diff == 0) {
        timeStatus = "Вернуть сегодня";
        timeColor = PulseColors.orange;
      } else {
        timeStatus = "Осталось $diff дн.";
        timeColor = PulseColors.green.withValues(alpha: 0.7);
      }
    }

    // Расчет процента/суммы переплаты
    final initialAmount = debt.amount.toDouble() / 100;
    final extra = currentAmount - initialAmount;
    final hasExtra = extra > 0;

    // ОБЕРТКА ДЛЯ РЕДАКТИРОВАНИЯ (Клик по всей карточке)
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // Открываем диалог редактирования, передавая текущий долг
        showDialog(
          context: context,
          builder: (_) => AddDebtDialog(debt: debt),
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
            // ВЕРХНЯЯ ЧАСТЬ (Инфо)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Иконка
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    debt.isOweMe ? Icons.arrow_downward : Icons.arrow_upward,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),

                // Название и статус
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeStatus,
                        style: TextStyle(
                          color: timeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Сумма
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${fmt.format(currentAmount)} ₽",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    if (hasExtra)
                      Text(
                        "+${fmt.format(extra)} ₽ (${debt.interestType == 'percent' ? '${debt.interestRate}%' : 'фикс'})",
                        style: const TextStyle(
                          color: PulseColors.orange,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // НИЖНЯЯ ЧАСТЬ (Действия)
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Дата начала
                Text(
                  "От: ${DateFormat('dd.MM.yyyy').format(debt.startDate)}",
                  style: const TextStyle(color: Colors.white24, fontSize: 11),
                ),

                // Кнопка ПОГАСИТЬ (Отдельный обработчик нажатия)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact(); // Более сильный отклик для важного действия
                    showDialog(
                      context: context,
                      builder: (_) => RepayDebtDialog(debt: debt),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: PulseColors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: PulseColors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: PulseColors.green,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "ПОГАСИТЬ",
                          style: TextStyle(
                            color: PulseColors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
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
  }
}
