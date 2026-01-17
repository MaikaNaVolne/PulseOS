import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/pulse_theme.dart';
import '../../../core/ui_kit/pulse_overlays.dart';
import '../../../core/utils/app_routes.dart';
import '../../wallet/presentation/wallet_provider.dart';

class BentoGrid extends StatelessWidget {
  const BentoGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();
    final double amout = provider.totalBalance.toDouble() / 100;
    return Column(
      children: [
        // ПЕРВЫЙ РЯД: Кошелек и Пульс
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _BentoCard(
                height: 160,
                title: "Баланс",
                value: "$amout ₽",
                subtitle: "+12% в этом мес.",
                icon: Icons.account_balance_wallet_outlined,
                color: PulseColors.primary,
                onTap: () => Navigator.pushNamed(context, AppRoutes.wallet),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _BentoCard(
                height: 160,
                title: "Пульс",
                value: "72",
                unit: "BPM",
                icon: FontAwesomeIcons.heartPulse,
                color: PulseColors.red,
                onTap: () => PulseOverlays.showComingSoon(
                  context,
                  featureName: "Здоровье",
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ВТОРОЙ РЯД: Сон и Еда
        Row(
          children: [
            Expanded(
              child: _BentoCard(
                height: 130,
                title: "Сон",
                value: "7.5",
                unit: "ч",
                subtitle: "Отлично",
                icon: FontAwesomeIcons.moon,
                color: PulseColors.purple,
                onTap: () =>
                    PulseOverlays.showComingSoon(context, featureName: "Сон"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BentoCard(
                height: 130,
                title: "Еда",
                value: "1250",
                unit: "ккал",
                icon: Icons.restaurant_menu_rounded,
                color: PulseColors.orange,
                onTap: () =>
                    PulseOverlays.showComingSoon(context, featureName: "Еда"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BentoCard extends StatelessWidget {
  final String title;
  final String value;
  final String? unit;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final double height;
  final VoidCallback onTap;

  const _BentoCard({
    required this.title,
    required this.value,
    this.unit,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      // ГЕНЕРАЦИЯ ФОРМЫ (ВНЕШНЯЯ ОБОЛОЧКА)
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: height,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            // ГЕНЕРАЦИЯ СТРУКТУРЫ (РАСПОЛОЖЕНИЕ ЭЛЕМЕНТОВ)
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Блок иконки
                _generateIconShape(),

                // Блок данных (тексты)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _generateValueText(),
                    const SizedBox(height: 4),
                    _generateTitleText(),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      _generateSubtitleText(),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ГЕНЕРАЦИЯ ФОРМЫ (ИКОНКА)
  Widget _generateIconShape() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  // ГЕНЕРАЦИЯ ТЕКСТА (ЗНАЧЕНИЕ И ЕДИНИЦЫ)
  Widget _generateValueText() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (unit != null) ...[
            const SizedBox(width: 4),
            Text(
              unit!,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ГЕНЕРАЦИЯ ТЕКСТА (ЗАГОЛОВОК)
  Widget _generateTitleText() {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: color.withValues(alpha: 0.8),
        fontSize: 9,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  // ГЕНЕРАЦИЯ ТЕКСТА (ПОДЗАГОЛОВОК)
  Widget _generateSubtitleText() {
    return Text(
      subtitle!,
      style: const TextStyle(color: Colors.white38, fontSize: 10),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
