import 'package:flutter/material.dart';
import '../../../../../core/theme/pulse_theme.dart';

class MiniCalendar extends StatelessWidget {
  const MiniCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 31,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          bool hasPlan = [5, 12, 15, 20].contains(index + 1);
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hasPlan
                  ? PulseColors.purple.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: hasPlan
                  ? Border.all(color: PulseColors.purple.withValues(alpha: 0.3))
                  : null,
            ),
            child: Text(
              "${index + 1}",
              style: TextStyle(
                color: hasPlan ? Colors.white : Colors.white24,
                fontSize: 10,
              ),
            ),
          );
        },
      ),
    );
  }
}
