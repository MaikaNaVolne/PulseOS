import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/pulse_theme.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/ui_kit/pulse_text_field.dart';

class ApiKeyDialog extends StatefulWidget {
  const ApiKeyDialog({super.key});

  @override
  State<ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<ApiKeyDialog> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Загружаем текущий токен, если есть
    final settings = sl<SettingsService>();
    _controller.text = settings.receiptToken ?? "";
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() async {
    final token = _controller.text.trim();
    if (token.isEmpty) return;

    final settings = sl<SettingsService>();
    await settings.setReceiptToken(token);

    if (mounted)
      Navigator.pop(context, true); // Возвращаем true, если сохранили
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() {
        _controller.text = data!.text!;
      });
    }
  }

  void _openWebsite() async {
    final url = Uri.parse("https://proverkacheka.com");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Не удалось открыть ссылку")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: const Color(0xFF1E202C).withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Настройка сканера",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                "Для автоматического получения данных с чека нужен API-ключ. Это бесплатно.",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),

              // Инструкция
              _Step("1. Перейди на сайт proverkacheka.com"),
              _Step("2. Зарегистрируйся и найди 'API токен' в профиле"),
              _Step("3. Скопируй и вставь его сюда:"),

              const SizedBox(height: 12),

              // Кнопка перехода на сайт
              GestureDetector(
                onTap: _openWebsite,
                child: const Text(
                  "Открыть сайт сервиса ->",
                  style: TextStyle(
                    color: PulseColors.blue,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    decorationColor: PulseColors.blue,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Поле ввода с кнопкой вставки
              Row(
                children: [
                  Expanded(
                    child: PulseTextField(
                      controller: _controller,
                      label: "API Токен",
                      icon: Icons.vpn_key,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _pasteFromClipboard();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PulseColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: PulseColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.paste,
                        color: PulseColors.primary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Кнопка Сохранить
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PulseColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "СОХРАНИТЬ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String text;
  const _Step(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
    );
  }
}
