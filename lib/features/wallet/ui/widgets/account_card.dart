import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/pulse_theme.dart';

class AccountCard extends StatelessWidget {
  final String name;
  final String balance;
  final String? cardNumber;
  final Color accentColor;
  final VoidCallback onTap;

  const AccountCard({
    super.key,
    required this.name,
    required this.balance,
    this.cardNumber,
    this.accentColor = PulseColors.blue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 20, top: 10, bottom: 10, left: 1),
        // ГЕНЕРАЦИЯ ФОРМЫ (НЕОНОВОЕ СВЕЧЕНИЕ)
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.15),
              blurRadius: 2,
              spreadRadius: -2,
              offset: const Offset(4, 9), // Смещаем вниз для объема
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                // Градиент самого стекла
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                // Тонкая обводка для подчеркивания формы
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ГЕНЕРАЦИЯ ТЕКСТА И ЭЛЕМЕНТОВ
                  _buildTopRow(),
                  _buildBalanceText(),
                  _buildBottomRow(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          name.toUpperCase(),
          style: TextStyle(
            color: accentColor.withValues(alpha: 0.8), // Текст в цвет карты
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        Icon(Icons.nfc, color: Colors.white.withValues(alpha: 0.3), size: 18),
      ],
    );
  }

  Widget _buildBalanceText() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        "$balance ₽",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _maskCardNumber(cardNumber),
          style: const TextStyle(
            color: Colors.white38,
            fontFamily: 'monospace',
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        // Маленький декоративный чип
        Container(
          width: 32,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
      ],
    );
  }

  String _maskCardNumber(String? number) {
    if (number == null || number.length < 4) return "•••• 0000";
    return "•••• ${number.substring(number.length - 4)}";
  }
}
