import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PulseColors {
  // Фон: глубокий темный космос
  static const background = Color(0xFF0F1115);
  static const cardColor = Color(0xFF181A20); // Чуть светлее для карточек

  // Неоновые акценты (твоя палитра)
  static const primary = Color(0xFF86EFAC); // Neon Green (Основной)
  static const blue = Color(0xFF60A5FA);
  static const purple = Color(0xFFC084FC);
  static const pink = Color(0xFFF472B6);
  static const orange = Color(0xFFFB923C);
  static const red = Color(0xFFF87171);
  static const teal = Color(0xFF2DD4BF);
  static const yellow = Color(0xFFFACC15);
  static const green = Color(0xFF22C55E);

  // Текст
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF9CA3AF); // Cool Gray
}

class PulseTheme {
  static ThemeData get darkTheme {
    // Берем темную тему как базу
    final base = ThemeData.dark();

    // Настраиваем шрифты (Manrope - современный, геометричный)
    final textTheme = GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: PulseColors.textPrimary,
        letterSpacing: -1,
      ),
      titleLarge: GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: PulseColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 14,
        color: PulseColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: PulseColors.background,
      primaryColor: PulseColors.primary,
      // Настройка цветовой схемы Material 3
      colorScheme: const ColorScheme.dark(
        primary: PulseColors.primary,
        surface: PulseColors.cardColor,
        onSurface: Colors.white,
        error: PulseColors.red,
      ),
      textTheme: textTheme,
      // Убираем тень у AppBar по умолчанию
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
