import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Круглая стеклянная кнопка с иконкой
class GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const GlassCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact(); // Тактильный отклик при нажатии
        onTap();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Эффект стекла
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              // Полупрозрачный белый фон
              color: Colors.white.withValues(alpha: .05),
              shape: BoxShape.circle,
              // Тонкая белая обводка
              border: Border.all(color: Colors.white.withValues(alpha: .1)),
            ),
            child: Icon(
              icon,
              color: Colors.white.withValues(
                alpha: .9,
              ), // Иконка чуть прозрачная
              size: size * 0.45,
            ),
          ),
        ),
      ),
    );
  }
}
