import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pulseos/features/wallet/presentation/wallet_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/ui_kit/pulse_page.dart';
import '../../../../core/theme/pulse_theme.dart';
import '../../domain/logic/planning_calculator.dart';
import 'dialog/add_planned_dialog.dart';
import 'widgets/plan_fact_card.dart';
import 'widgets/planning_chart.dart';
import 'widgets/mini_calendar.dart';

class PlanningPage extends StatelessWidget {
  const PlanningPage({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    return PulsePage(
      title: "План",
      subtitle: "ОКТЯБРЬ 2024",
      accentColor: PulseColors.purple,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPlannedDialog(context),
        backgroundColor: PulseColors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<PlannedTransaction>>(
        stream: sl<AppDatabase>().planningDao.watchAllPlanned(),
        builder: (context, snapshot) {
          final planned = snapshot.data ?? [];

          // Считаем статистику через калькулятор
          // Для факта пока берем все транзакции кошелька (в идеале фильтровать по месяцу)
          final stats = PlanningCalculator.calculate(
            planned,
            wallet.transactions.map((t) => t.transaction).toList(),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Сводка План/Факт
              PlanFactCard(stats: stats),

              const SizedBox(height: 24),

              // 2. График
              const PlanningChart(),

              const SizedBox(height: 32),

              // 3. Мини-календарь
              const MiniCalendar(),

              const SizedBox(height: 32),

              // 4. Список запланированного
              const Text(
                "СПИСОК ПЛАНОВ",
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              ...planned.map((p) => _PlannedTile(item: p)),
            ],
          );
        },
      ),
    );
  }

  void _showAddPlannedDialog(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog(context: context, builder: (_) => const AddPlannedDialog());
  }
}

class _PlannedTile extends StatelessWidget {
  final PlannedTransaction item;
  const _PlannedTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: item.isCompleted
            ? Border.all(color: PulseColors.primary.withValues(alpha: 0.2))
            : null,
      ),
      child: Row(
        children: [
          Icon(
            item.type == 'income'
                ? Icons.add_circle_outline
                : Icons.remove_circle_outline,
            color: item.type == 'income' ? PulseColors.green : PulseColors.red,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                color: item.isCompleted ? Colors.white38 : Colors.white,
              ),
            ),
          ),
          Text(
            "${(item.amount.toDouble() / 100).toInt()} ₽",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
