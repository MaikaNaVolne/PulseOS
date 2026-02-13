import '../../../../core/database/app_database.dart';

class WeeklySleepStats {
  final List<SleepEntry> entries;
  final DateTime weekStart;

  WeeklySleepStats({required this.entries, required this.weekStart});

  // Средняя длительность за неделю
  double get avgDuration {
    if (entries.isEmpty) return 0;
    final totalMins = entries.fold(
      0,
      (sum, e) => sum + e.endTime.difference(e.startTime).inMinutes,
    );
    return (totalMins / entries.length) / 60.0;
  }

  // Среднее качество
  double get avgQuality {
    if (entries.isEmpty) return 0;
    return entries.fold(0, (sum, e) => sum + e.quality) / entries.length;
  }

  int get totalCount => entries.length;
}
