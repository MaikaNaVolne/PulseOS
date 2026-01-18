import 'package:flutter/material.dart';

// Карта всех доступных иконок
final Map<String, IconData> _icons = {
  // Финансы
  'wallet': Icons.account_balance_wallet,
  'money': Icons.attach_money,
  'bank': Icons.account_balance,
  'card': Icons.credit_card,
  'savings': Icons.savings,

  // Категории
  'shopping': Icons.shopping_cart,
  'food': Icons.restaurant,
  'car': Icons.directions_car,
  'health': Icons.medical_services,
  'home': Icons.home,
  'gift': Icons.card_giftcard,
  'education': Icons.school,
  'entertainment': Icons.movie,
  'travel': Icons.flight,
  'sport': Icons.fitness_center,
  'pets': Icons.pets,
  'cafe': Icons.local_cafe,
  'tech': Icons.computer,
  'clothes': Icons.checkroom,

  // Общее
  'category': Icons.category,
  'help': Icons.help_outline,
};

// Группировка для пикера (чтобы выбирать по темам)
final Map<String, List<String>> iconCategories = {
  'Популярное': ['shopping', 'food', 'car', 'home', 'health'],
  'Досуг': ['entertainment', 'cafe', 'sport', 'travel'],
  'Финансы': ['wallet', 'card', 'bank', 'savings', 'money'],
  'Разное': ['gift', 'education', 'pets', 'tech', 'clothes'],
};

// Главная функция: Получить иконку по ключу
IconData getIcon(String key) {
  return _icons[key] ?? Icons.help_outline;
}
