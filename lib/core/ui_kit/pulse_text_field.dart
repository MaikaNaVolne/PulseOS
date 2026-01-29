import 'package:flutter/material.dart';

class PulseTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final TextInputType type;
  final bool autoFocus;
  final ValueChanged<String>? onChanged;

  const PulseTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.type = TextInputType.text,
    this.autoFocus = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        autofocus: autoFocus,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          icon: icon != null
              ? Icon(icon, color: Colors.white30, size: 20)
              : null,
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
          border: InputBorder.none,
          // Убираем паддинги, так как они есть у контейнера
          contentPadding: icon == null
              ? const EdgeInsets.symmetric(vertical: 12)
              : EdgeInsets.zero,
        ),
      ),
    );
  }
}
