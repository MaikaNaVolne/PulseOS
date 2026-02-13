import '../../../../core/database/app_database.dart';

/// Объединенная модель для UI
class SleepEntryWithFactors {
  final SleepEntry entry;
  final List<SleepFactor> factors;

  SleepEntryWithFactors({required this.entry, required this.factors});

  double get durationInHours =>
      entry.endTime.difference(entry.startTime).inMinutes / 60.0;

  // Формула эффективности из старого кода (настроена под 1-10)
  double get efficiencyScore {
    return (entry.quality * 0.3) +
        (entry.wakeEase * 0.2) +
        (entry.energyLevel * 0.5);
  }
}

/// Результат анализа (как в старом коде, но адаптированный)
class SleepInsight {
  final double sleepDebt;
  final String coachMessage;
  final DateTime? suggestedBedtime;
  final bool isCalibrated;

  SleepInsight({
    required this.sleepDebt,
    required this.coachMessage,
    this.suggestedBedtime,
    required this.isCalibrated,
  });
}
