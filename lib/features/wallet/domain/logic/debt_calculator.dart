import '../../../../core/database/app_database.dart';

class DebtCalculator {
  static double calculateCurrentAmount(Debt debt, [DateTime? now]) {
    final DateTime calcDate = now ?? DateTime.now();
    double total = debt.amount.toDouble() / 100.0;

    if (debt.isClosed) return total;

    // 1. Считаем проценты (Interest)
    if (debt.interestType != 'none') {
      total += _calculateExtra(
        principal: total,
        type: debt.interestType,
        period: debt.interestPeriod,
        rate: debt.interestRate,
        startDate: debt.startDate,
        endDate: debt.dueDate ?? calcDate,
        calcDate: calcDate,
      );
    }

    // 2. Считаем штрафы
    if (debt.dueDate != null &&
        calcDate.isAfter(debt.dueDate!) &&
        debt.penaltyType != 'none') {
      total += _calculateExtra(
        principal: total,
        type: debt.penaltyType,
        period: debt.penaltyPeriod,
        rate: debt.penaltyRate,
        startDate: debt.dueDate!,
        endDate: calcDate,
        calcDate: calcDate,
      );
    }

    return total;
  }

  static double _calculateExtra({
    required double principal,
    required String type,
    String? period,
    required double rate,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime calcDate,
  }) {
    if (type == 'fixed') {
      return rate;
    }

    if (type == 'percent' && period != null) {
      // Считаем количество полных периодов
      final duration = endDate.difference(startDate);
      if (duration.isNegative) return 0;

      int periodsCount = 0;
      switch (period) {
        case 'day':
          periodsCount = duration.inDays;
          break;
        case 'week':
          periodsCount = (duration.inDays / 7).floor();
          break;
        case 'month':
          periodsCount = (duration.inDays / 30).floor();
          break;
        case 'year':
          periodsCount = (duration.inDays / 365).floor();
          break;
      }

      return principal * (rate / 100.0) * periodsCount;
    }

    return 0.0;
  }
}
