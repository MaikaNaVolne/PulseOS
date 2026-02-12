import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/database/app_database.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/theme/pulse_theme.dart';
import '../../../domain/models/price_point.dart';

class PriceHistorySheet extends StatelessWidget {
  final String shopName;
  final String productName;

  const PriceHistorySheet({
    super.key,
    required this.shopName,
    required this.productName,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        height: 450,
        decoration: BoxDecoration(
          color: const Color(0xFF161821).withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<List<PricePoint>>(
          stream: sl<AppDatabase>().shopsDao.watchProductPriceHistory(
            shopName,
            productName,
          ),
          builder: (context, snapshot) {
            final history = snapshot.data ?? [];

            if (history.length < 2) {
              return _buildNotEnoughData();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                Expanded(child: _buildChart(history)),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          productName.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          "ИЗМЕНЕНИЕ ЦЕНЫ В $shopName",
          style: const TextStyle(
            color: PulseColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildNotEnoughData() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 48,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          const Text(
            "Нужно хотя бы 2 покупки",
            style: TextStyle(color: Colors.white38),
          ),
          Text(
            "для построения графика",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<PricePoint> history) {
    final spots = history
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.price))
        .toList();

    double minP = history.map((e) => e.price).reduce((a, b) => a < b ? a : b);
    double maxP = history.map((e) => e.price).reduce((a, b) => a > b ? a : b);
    double padding = (maxP - minP) == 0 ? 10 : (maxP - minP) * 0.3;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, m) => Text(
                "${v.toInt()}",
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, m) {
                int i = v.toInt();
                if (i >= 0 &&
                    i < history.length &&
                    (i == 0 || i == history.length - 1)) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('d.MM').format(history[i].date),
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: minP - padding,
        maxY: maxP + padding,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: PulseColors.primary,
            barWidth: 4,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  PulseColors.primary.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
