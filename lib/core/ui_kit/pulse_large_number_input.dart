import 'package:flutter/material.dart';

class PulseLargeNumberInput extends StatelessWidget {
  final TextEditingController controller;
  final String suffix;
  final Color color;

  const PulseLargeNumberInput({
    super.key,
    required this.controller,
    this.suffix = "₽",
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w900,
          color: color,
          height: 1,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "0",
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.1)),
          suffixText: suffix,
          suffixStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
