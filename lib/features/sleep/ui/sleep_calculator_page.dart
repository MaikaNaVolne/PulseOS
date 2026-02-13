import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/pulse_theme.dart';
import '../../../core/ui_kit/pulse_page.dart';

class SleepCalculatorPage extends StatefulWidget {
  const SleepCalculatorPage({super.key});

  @override
  State<SleepCalculatorPage> createState() => _SleepCalculatorPageState();
}

class _SleepCalculatorPageState extends State<SleepCalculatorPage> {
  // По умолчанию предлагаем текущее время
  TimeOfDay _bedtime = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    return PulsePage(
      title: "Будильник",
      subtitle: "ЦИКЛЫ СНА",
      accentColor: PulseColors.purple,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ЕСЛИ Я ЛЯГУ В...",
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          // Выбор времени
          _buildTimePicker(),

          const SizedBox(height: 32),

          const Text(
            "ЛУЧШЕЕ ВРЕМЯ ДЛЯ ПОДЪЕМА",
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "С учетом 15 минут на засыпание",
            style: TextStyle(color: Colors.white12, fontSize: 11),
          ),
          const SizedBox(height: 16),

          // Список рекомендаций (4, 5, 6 циклов)
          _buildResultCard(cycles: 6, label: "Отлично (9ч)"),
          _buildResultCard(
            cycles: 5,
            label: "Рекомендуем (7.5ч)",
            isRecommended: true,
          ),
          _buildResultCard(cycles: 4, label: "Минимум (6ч)"),
          _buildResultCard(cycles: 3, label: "Мало (4.5ч)"),

          const SizedBox(height: 20),
          const Center(
            child: Text(
              "Один цикл сна длится в среднем 90 минут",
              style: TextStyle(
                color: Colors.white10,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _bedtime,
          builder: (context, child) => Theme(
            data: PulseTheme.darkTheme.copyWith(
              colorScheme: const ColorScheme.dark(
                primary: PulseColors.purple,
                surface: PulseColors.cardColor,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _bedtime = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: PulseColors.purple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: PulseColors.purple.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _bedtime.format(context),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const Icon(Icons.access_time_rounded, color: PulseColors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required int cycles,
    required String label,
    bool isRecommended = false,
  }) {
    // Логика расчета:
    final now = DateTime.now();
    final bedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _bedtime.hour,
      _bedtime.minute,
    );

    // Добавляем 15 минут на засыпание + количество циклов по 90 минут
    final wakeUpTime = bedDateTime.add(Duration(minutes: 15 + (cycles * 90)));
    final timeStr = DateFormat('HH:mm').format(wakeUpTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isRecommended
            ? PulseColors.purple.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRecommended
              ? PulseColors.purple.withValues(alpha: 0.4)
              : Colors.white10,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isRecommended ? Colors.white : Colors.white70,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: isRecommended ? PulseColors.purple : Colors.white24,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$cycles",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "ЦИКЛОВ",
                style: TextStyle(
                  color: Colors.white10,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
