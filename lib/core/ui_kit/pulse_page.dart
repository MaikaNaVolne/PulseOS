import 'package:flutter/material.dart';
import '../theme/pulse_theme.dart';
import 'pulse_buttons.dart';

class PulsePage extends StatelessWidget {
  /// Основной заголовок (Большой)
  final String title;

  /// Надзаголовок (Маленький, цветной)
  final String? subtitle;

  /// Контент страницы
  final Widget body;

  /// Цвет акцента для этой страницы (градиент заголовка)
  final Color accentColor;

  /// Кнопки справа в углу (Настройки, Поиск и т.д.)
  final List<Widget>? actions;

  /// Нужна ли кнопка "Назад"? (Если null, Flutter решит сам, но можно форсировать)
  final bool? showBackButton;

  /// Нужен ли скролл? (Для списков true, для фикс. экранов false)
  final bool useScroll;

  /// Кнопка действия (FAB)
  final Widget? floatingActionButton;

  const PulsePage({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.accentColor = PulseColors.primary,
    this.actions,
    this.showBackButton,
    this.useScroll = true,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    // Проверяем, можем ли мы вернуться назад (для авто-кнопки)
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final shouldShowBack = showBackButton ?? canPop;

    return GestureDetector(
      // Скрываем клавиатуру при тапе в пустоту
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: PulseColors.background,
        floatingActionButton: floatingActionButton,
        body: Stack(
          children: [
            // СЛОЙ 1: ФОН (Пока просто градиент, позже добавим AnimatedBackground)
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.5,
                  colors: [
                    Color(0xFF1A1C24), // Чуть светлее в углу
                    PulseColors.background,
                  ],
                ),
              ),
            ),

            // СЛОЙ 2: КОНТЕНТ
            SafeArea(
              child: Column(
                children: [
                  // --- ХЕДЕР ---
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Кнопка назад
                        if (shouldShowBack) ...[
                          GlassCircleButton(
                            icon: Icons.arrow_back_ios_new,
                            onTap: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 16),
                        ],

                        // Заголовки
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (subtitle != null)
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [Colors.white, accentColor],
                                  ).createShader(bounds),
                                  child: Text(
                                    subtitle!.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Кнопки справа
                        if (actions != null) ...actions!,
                      ],
                    ),
                  ),

                  // --- ТЕЛО ---
                  Expanded(
                    child: useScroll
                        ? SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: 100,
                              ), // Отступ под FAB
                              child: body,
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: body,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
