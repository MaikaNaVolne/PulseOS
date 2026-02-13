import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/database/app_database.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/pulse_theme.dart';
import '../../../../core/ui_kit/pulse_page.dart';
import '../../../core/ui_kit/pulse_button.dart';

class SleepSettingsPage extends StatefulWidget {
  const SleepSettingsPage({super.key});

  @override
  State<SleepSettingsPage> createState() => _SleepSettingsPageState();
}

class _SleepSettingsPageState extends State<SleepSettingsPage> {
  TimeOfDay _wakeTime = const TimeOfDay(hour: 8, minute: 0);
  double _duration = 8.5;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentGoals();
  }

  void _loadCurrentGoals() async {
    final goals = await sl<AppDatabase>().sleepDao.getGoals();
    if (goals != null) {
      setState(() {
        _wakeTime = TimeOfDay(
          hour: goals.targetWakeHour,
          minute: goals.targetWakeMinute,
        );
        _duration = goals.targetDuration;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _save() async {
    HapticFeedback.mediumImpact();
    // Используем обычный конструктор Companion, обертывая всё в Value
    await sl<AppDatabase>().sleepDao.updateGoals(
      SleepGoalsCompanion(
        id: const drift.Value(1), // Настройки всегда под ID 1
        targetWakeHour: drift.Value(_wakeTime.hour),
        targetWakeMinute: drift.Value(_wakeTime.minute),
        targetDuration: drift.Value(_duration),
      ),
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return PulsePage(
      title: "Цели сна",
      subtitle: "НАСТРОЙКА РЕЖИМА",
      accentColor: PulseColors.purple,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            title: "ВРЕМЯ ПОДЪЕМА",
            icon: Icons.wb_sunny_rounded,
            color: PulseColors.orange,
            child: GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _wakeTime,
                );
                if (picked != null) setState(() => _wakeTime = picked);
              },
              child: Center(
                child: Text(
                  _wakeTime.format(context),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          _buildCard(
            title: "ДЛИТЕЛЬНОСТЬ",
            icon: Icons.king_bed_rounded,
            color: PulseColors.purple,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Желаемый сон",
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      "${_duration.toStringAsFixed(1)}ч",
                      style: const TextStyle(
                        color: PulseColors.purple,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _duration,
                  min: 4,
                  max: 12,
                  divisions: 16,
                  activeColor: PulseColors.purple,
                  onChanged: (v) => setState(() => _duration = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
          PulseButton(
            text: "СОХРАНИТЬ",
            onPressed: _save,
            color: PulseColors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
