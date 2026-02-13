import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/di/service_locator.dart';

class SleepProvider extends ChangeNotifier {
  final AppDatabase _db = sl<AppDatabase>();
  StreamSubscription? _subscription;

  double todayTotalHours = 0;
  int todayMainQuality = 0;
  bool isLoading = true;

  SleepProvider() {
    _init();
  }

  void _init() {
    _subscription = _db.sleepDao.watchAllSleep().listen((entries) {
      _calculateTodayStats(entries);
      isLoading = false;
      notifyListeners();
    });
  }

  void _calculateTodayStats(List<SleepEntry> entries) {
    final now = DateTime.now();
    final dayEntries = entries
        .where((e) => DateUtils.isSameDay(e.endTime, now))
        .toList();

    double total = 0;
    for (var e in dayEntries) {
      total += e.endTime.difference(e.startTime).inMinutes / 60.0;
    }
    todayTotalHours = total;

    if (dayEntries.isNotEmpty) {
      final main =
          dayEntries.where((e) => e.sleepType == 'night').firstOrNull ??
          dayEntries.first;
      todayMainQuality = main.quality;
    } else {
      todayMainQuality = 0;
    }
  }

  String get qualityLabel {
    if (todayTotalHours == 0) return "Нет данных";
    if (todayMainQuality >= 9) return "Отлично";
    if (todayMainQuality >= 7) return "Хорошо";
    if (todayMainQuality >= 5) return "Нормально";
    return "Плохо";
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
