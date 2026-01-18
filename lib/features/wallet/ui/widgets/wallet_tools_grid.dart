import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pulseos/core/utils/app_routes.dart';
import '../../../../../core/theme/pulse_theme.dart';
import '../../../../../core/ui_kit/pulse_overlays.dart';

class WalletToolsGrid extends StatelessWidget {
  const WalletToolsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    // Конфигурация инструментов
    final List<Map<String, dynamic>> tools = [
      {
        'title': 'Долги',
        'icon': Icons.handshake_outlined,
        'color': PulseColors.orange,
      },
      {
        'title': 'Инсайты',
        'icon': Icons.auto_awesome,
        'color': PulseColors.purple,
      },
      {
        'title': 'Магазины',
        'icon': Icons.storefront,
        'color': PulseColors.blue,
      },
      {
        'title': 'План',
        'icon': Icons.calendar_today,
        'color': PulseColors.teal,
      },
      {
        'title': 'Отчеты',
        'icon': Icons.pie_chart_outline,
        'color': PulseColors.pink,
      },
      {
        'title': 'Автоматика',
        'icon': Icons.psychology_outlined,
        'color': PulseColors.primary,
      },
      {
        'title': 'Категории',
        'icon': Icons.category_outlined,
        'color': PulseColors.yellow,
        'route': AppRoutes.category,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок секции (опционально, для красоты)
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 4),
          child: Text(
            "ИНСТРУМЕНТЫ",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),

        // Сама сетка
        GridView.builder(
          shrinkWrap: true, // Чтобы GridView не занимал бесконечное место
          physics:
              const NeverScrollableScrollPhysics(), // Скроллить будем всю страницу
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 колонки
            crossAxisSpacing: 12, // Отступ между колонками
            mainAxisSpacing: 12, // Отступ между рядами
            childAspectRatio: 2.2, // Пропорции карточки (вытянутая кнопка)
          ),
          itemCount: tools.length,
          itemBuilder: (context, index) {
            final tool = tools[index];
            return _ToolCard(
              title: tool['title'],
              icon: tool['icon'],
              color: tool['color'],
              onTap: () => {
                if (tool['route'] != null)
                  {Navigator.pushNamed(context, tool['route']!)}
                else
                  {
                    PulseOverlays.showComingSoon(
                      context,
                      featureName: tool['title'],
                    ),
                  },
              },
            );
          },
        ),
      ],
    );
  }
}

// Внутренний виджет плитки
class _ToolCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ToolCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Цветная иконка в круге
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),

                // Текст
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Стрелочка (еле заметная)
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.1),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
