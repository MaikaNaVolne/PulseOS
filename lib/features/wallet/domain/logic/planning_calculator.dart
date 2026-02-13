import '../../../../core/database/app_database.dart';

class PlanningStats {
  final double plannedIncome;
  final double plannedExpense;
  final double actualIncome;
  final double actualExpense;

  PlanningStats({
    required this.plannedIncome,
    required this.plannedExpense,
    required this.actualIncome,
    required this.actualExpense,
  });

  double get planBalance => plannedIncome - plannedExpense;
  double get actualBalance => actualIncome - actualExpense;
  double get diff => actualBalance - planBalance;
}

class PlanningCalculator {
  static PlanningStats calculate(
    List<PlannedTransaction> planned,
    List<Transaction> actual,
  ) {
    double pInc = 0;
    double pExp = 0;
    double aInc = 0;
    double aExp = 0;

    for (var p in planned) {
      if (p.type == 'income')
        pInc += p.amount.toDouble() / 100;
      else
        pExp += p.amount.toDouble() / 100;
    }

    for (var a in actual) {
      if (a.type == 'income')
        aInc += a.amount.toDouble() / 100;
      else if (a.type == 'expense')
        aExp += a.amount.toDouble() / 100;
    }

    return PlanningStats(
      plannedIncome: pInc,
      plannedExpense: pExp,
      actualIncome: aInc,
      actualExpense: aExp,
    );
  }
}
