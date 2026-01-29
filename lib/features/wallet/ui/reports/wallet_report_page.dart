import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/pulse_theme.dart';
import '../../../../core/ui_kit/pulse_buttons.dart';
import '../../../../core/ui_kit/pulse_page.dart';
import '../../presentation/wallet_provider.dart';

class WalletReportPage extends StatelessWidget {
  const WalletReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();
    final summary = provider.periodSummary;

    // Форматирование даты для заголовка (например: Октябрь 2024)
    final dateLabel = DateFormat(
      'MMMM yyyy',
      'ru',
    ).format(provider.reportStartDate);

    return PulsePage(
      title: "Отчеты",
      subtitle: "АНАЛИТИКА",
      accentColor: PulseColors.purple,
      showBackButton: true,
      body: Column(
        children: [
          // 1. УПРАВЛЕНИЕ ПЕРИОДОМ
          _buildDateNavigator(context, provider, dateLabel),

          const SizedBox(height: 24),

          // 2. КАРТОЧКИ СВОДКИ
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: "Доходы",
                  amount: summary['income'] ?? 0,
                  color: PulseColors.green,
                  icon: Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: "Расходы",
                  amount: summary['expense'] ?? 0,
                  color: PulseColors.red,
                  icon: Icons.arrow_upward,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // 3. ЗАГЛОВКА ДЛЯ ДИАГРАММЫ (Появится в следующей задаче)
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "РАСПРЕДЕЛЕНИЕ",
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 100), // Заглушка под будущий график
          const Center(
            child: Text(
              "График будет здесь...",
              style: TextStyle(color: Colors.white10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavigator(
    BuildContext context,
    WalletProvider provider,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              final newStart = DateTime(
                provider.reportStartDate.year,
                provider.reportStartDate.month - 1,
                1,
              );
              final newEnd = DateTime(
                provider.reportStartDate.year,
                provider.reportStartDate.month,
                0,
                23,
                59,
                59,
              );
              provider.setReportPeriod(newStart, newEnd);
            },
            icon: const Icon(Icons.chevron_left, color: Colors.white54),
          ),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
          IconButton(
            onPressed: () {
              final newStart = DateTime(
                provider.reportStartDate.year,
                provider.reportStartDate.month + 1,
                1,
              );
              final newEnd = DateTime(
                provider.reportStartDate.year,
                provider.reportStartDate.month + 2,
                0,
                23,
                59,
                59,
              );
              provider.setReportPeriod(newStart, newEnd);
            },
            icon: const Icon(Icons.chevron_right, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              "${amount.toInt()} ₽",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
