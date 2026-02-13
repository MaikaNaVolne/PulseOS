import '../models/sleep_models.dart';

class SleepAnalyzer {
  static const double targetDuration = 8.0;

  static SleepInsight analyze(List<SleepEntryWithFactors> history) {
    if (history.isEmpty) {
      return SleepInsight(
        sleepDebt: 0,
        coachMessage: "Начни записывать сон, чтобы получить советы.",
        isCalibrated: false,
      );
    }

    // 1. Расчет долга за последние 7 дней
    double debt = 0;
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final recentSleeps = history
        .where((e) => e.entry.endTime.isAfter(weekAgo))
        .toList();

    // Суммируем недосып относительно 8 часов
    for (var s in recentSleeps) {
      debt += (targetDuration - s.durationInHours);
    }

    // 2. Логика коуча
    String message = "Твой режим в норме. Так держать!";
    DateTime? suggestion;

    if (debt > 2) {
      message = "Накопился долг сна. Сегодня стоит лечь на 30 мин раньше.";
      suggestion = now.subtract(const Duration(hours: 1));
    } else if (debt < -2) {
      message = "Ты отлично выспался за неделю. Энергия должна быть на высоте!";
    }

    return SleepInsight(
      sleepDebt: debt,
      coachMessage: message,
      suggestedBedtime: suggestion,
      isCalibrated: history.length >= 3,
    );
  }
}
