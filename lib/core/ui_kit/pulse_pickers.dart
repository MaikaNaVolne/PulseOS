import 'package:flutter/material.dart';
import '../theme/pulse_theme.dart';

class PulsePickers {
  /// Универсальный метод: Сначала Дата, потом Время.
  /// Возвращает полный [DateTime] или null, если пользователь отменил выбор.
  static Future<DateTime?> pickDateTime(
    BuildContext context, {
    required DateTime initialDate,
  }) async {
    // 1. Выбор Даты
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => _pickerTheme(child!),
    );

    if (pickedDate == null) return null;

    // 2. Сразу после даты - Выбор Времени
    if (!context.mounted) return null;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      builder: (context, child) => _pickerTheme(child!),
    );

    if (pickedTime == null) return null;

    // 3. Собираем всё в один объект
    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  /// Настройка внешнего вида стандартных пикеров под PulseOS
  static Widget _pickerTheme(Widget child) {
    return Theme(
      data: PulseTheme.darkTheme.copyWith(
        colorScheme: const ColorScheme.dark(
          primary: PulseColors.primary, // Цвет выделения
          onPrimary: Colors.black, // Текст на выделении
          surface: PulseColors.cardColor, // Фон окна
          onSurface: Colors.white, // Текст в окне
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: PulseColors.primary, // Цвет кнопок "ОК/Отмена"
          ),
        ),
      ),
      child: child,
    );
  }
}
