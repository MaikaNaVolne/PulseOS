import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/pulse_theme.dart';
import '../../../domain/models/category_stat_dto.dart';

class WalletPieChart extends StatelessWidget {
  final List<CategoryStatDto> stats;
  final double totalAmount;

  const WalletPieChart({
    super.key,
    required this.stats,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Сама диаграмма
          PieChart(
            PieChartData(
              sectionsSpace: 4, // Отступ между секциями
              centerSpaceRadius: 70, // Радиус "дырки" внутри
              startDegreeOffset: -90,
              sections: _buildSections(),
            ),
          ),

          // 2. Текст в центре
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "ИТОГО",
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Text(
                "${totalAmount.toInt()} ₽",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    if (stats.isEmpty) {
      // Если данных нет, рисуем пустое серое кольцо
      return [
        PieChartSectionData(
          color: Colors.white.withValues(alpha: 0.05),
          value: 1,
          title: '',
          radius: 12,
        ),
      ];
    }

    return stats.map((item) {
      final color = _hexToColor(item.category?.colorHex ?? '#808080');
      return PieChartSectionData(
        color: color,
        value: item.totalAmount,
        title: '', // Текст внутри секторов не нужен, сделаем список ниже
        radius: 14, // Толщина кольца
        // Подсветка (можно добавить при тапе)
        showTitle: false,
      );
    }).toList();
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000);
  }
}
