import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/pulse_theme.dart';

class SleepFactorsCard extends StatelessWidget {
  final String sleepId;
  const SleepFactorsCard({super.key, required this.sleepId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SleepFactor>>(
      future: sl<AppDatabase>().sleepDao.getFactorsForSleep(sleepId),
      builder: (context, snapshot) {
        final factors = snapshot.data ?? [];
        if (factors.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "ФАКТОРЫ ВЛИЯНИЯ",
              style: TextStyle(
                color: Colors.white24,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: factors.map((f) => _FactorChip(factor: f)).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _FactorChip extends StatelessWidget {
  final SleepFactor factor;
  const _FactorChip({required this.factor});

  @override
  Widget build(BuildContext context) {
    final isPos = factor.impactType == 'positive';
    final color = isPos ? PulseColors.primary : PulseColors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPos ? Icons.add : Icons.remove, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            factor.name,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
