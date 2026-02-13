import 'package:flutter/material.dart';
import '../../../../../core/theme/pulse_theme.dart';
import '../../../domain/logic/planning_calculator.dart';

class PlanFactCard extends StatelessWidget {
  final PlanningStats stats;

  const PlanFactCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildColumn("ПЛАН", stats.planBalance, PulseColors.purple),
              Container(width: 1, height: 40, color: Colors.white10),
              _buildColumn("ФАКТ", stats.actualBalance, PulseColors.primary),
            ],
          ),
          const SizedBox(height: 20),
          _buildDiffRow(),
        ],
      ),
    );
  }

  Widget _buildColumn(String label, double val, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white24,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "${val.toInt()} ₽",
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildDiffRow() {
    final isPositive = stats.diff >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: (isPositive ? PulseColors.green : PulseColors.red).withValues(
          alpha: 0.1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "Разница: ${isPositive ? '+' : ''}${stats.diff.toInt()} ₽",
        style: TextStyle(
          color: isPositive ? PulseColors.green : PulseColors.red,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
