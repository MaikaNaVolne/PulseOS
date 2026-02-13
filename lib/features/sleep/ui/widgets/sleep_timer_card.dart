import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/pulse_theme.dart';

class SleepTimerCard extends StatefulWidget {
  const SleepTimerCard({super.key});

  @override
  State<SleepTimerCard> createState() => _SleepTimerCardState();
}

class _SleepTimerCardState extends State<SleepTimerCard> {
  bool _isSleeping = false;

  void _toggleSleep() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isSleeping = !_isSleeping;
    });

    if (!_isSleeping) {
      // Здесь мы в будущем будем открывать диалог сохранения результата
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleSleep,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _isSleeping
              ? PulseColors.purple.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isSleeping
                ? PulseColors.purple
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_isSleeping ? PulseColors.purple : Colors.white)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isSleeping ? Icons.stop_rounded : Icons.play_arrow_rounded,
                color: _isSleeping ? PulseColors.purple : Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSleeping ? "Я СПЛЮ..." : "ЛЕЧЬ СПАТЬ",
                    style: TextStyle(
                      color: _isSleeping ? PulseColors.purple : Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    _isSleeping
                        ? "Нажми, чтобы проснуться"
                        : "Запустить таймер сна",
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (_isSleeping)
              const Icon(Icons.waves, color: PulseColors.purple, size: 20),
          ],
        ),
      ),
    );
  }
}
