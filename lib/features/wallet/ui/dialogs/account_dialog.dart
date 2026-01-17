import 'dart:ui';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/ui_kit/confirm_dialog.dart';
import '../../presentation/wallet_provider.dart';
import '../../../../core/theme/pulse_theme.dart';

class AccountDialog extends StatefulWidget {
  final Account? account;
  const AccountDialog({super.key, this.account});

  @override
  State<AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<AccountDialog> {
  final _digitsController = TextEditingController();
  var _nameController = TextEditingController();
  var _balanceController = TextEditingController();

  // Состояние переключателей
  bool _isMain = false;
  bool _isExcluded = false;

  final List<String> _colors = [
    '#2fa33d', // Green (Primary)
    '#60A5FA', // Blue
    '#F472B6', // Pink
    '#FB923C', // Orange
    '#C084FC', // Purple
    '#F87171', // Red
    '#2DD4BF', // Teal
  ];

  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    final acc = widget.account;
    _digitsController.text = widget.account?.cardNumber4 ?? '';
    // Заполняем данными, если редактируем
    _nameController = TextEditingController(text: widget.account?.name ?? '');

    _selectedColor = widget.account?.colorHex ?? _colors[0];

    // Баланс хранится в копейках (BigInt), конвертируем в рубли для UI
    double balance = 0;
    if (widget.account != null) {
      balance = widget.account!.balance.toDouble() / 100;
    }

    // Форматируем без .0, если число целое
    _balanceController = TextEditingController(
      text: balance == 0
          ? ''
          : balance.toStringAsFixed(balance % 1 == 0 ? 0 : 2),
    );

    // Инициализируем переключатели из базы
    _isMain = acc?.isMain ?? false;
    _isExcluded = acc?.isExcluded ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.isEmpty) return;

    final double amount =
        double.tryParse(_balanceController.text.replaceAll(',', '.')) ?? 0.0;
    final BigInt cents = BigInt.from((amount * 100).round());
    final String? lastFour = _digitsController.text.length == 4
        ? _digitsController.text
        : null;

    final provider = context.read<WalletProvider>();

    if (widget.account == null) {
      provider.addAccount(
        name: _nameController.text,
        balance: cents,
        colorHex: _selectedColor,
        lastFourDigits: lastFour,
        isMain: _isMain,
        isExcluded: _isExcluded,
      );
    } else {
      final updated = widget.account!.copyWith(
        name: _nameController.text,
        balance: cents,
        colorHex: _selectedColor,
        cardNumber4: drift.Value(lastFour),
        isMain: _isMain,
        isExcluded: _isExcluded,
      );
      provider.updateAccount(updated);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.account != null;
    final Color themeColor = _hexToColor(_selectedColor);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: PulseColors.cardColor.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEditing ? "Настройки счета" : "Новый счет",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              _buildTextField(
                controller: _nameController,
                label: "Название",
                icon: Icons.edit,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _balanceController,
                label: "Баланс",
                icon: Icons.account_balance_wallet,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _digitsController,
                label: "4 цифры карты",
                icon: Icons.credit_card,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 20),

              // --- ВЫБОР ЦВЕТА ---
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Цвет оформления",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                // На случай, если цветов будет много
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _colors.map((colorHex) {
                    final color = _hexToColor(colorHex);
                    final isSelected = _selectedColor == colorHex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor =
                              colorHex; // Теперь это сработает, так как это переменная
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 12),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2.5)
                              : Border.all(color: Colors.white10, width: 1),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.6),
                                    blurRadius: 10,
                                  ),
                                ]
                              : [],
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 20,
                                color: Colors.black45,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // --- ПЕРЕКЛЮЧАТЕЛИ ---
              _buildSwitchTile(
                title: "Основной счет",
                subtitle: "Будет выбираться по умолчанию",
                value: _isMain,
                onChanged: (val) => setState(() => _isMain = val),
                activeColor: themeColor,
              ),
              _buildSwitchTile(
                title: "Исключить из баланса",
                subtitle: "Не учитывать в общей сумме",
                value: _isExcluded,
                onChanged: (val) => setState(() => _isExcluded = val),
                activeColor: PulseColors.orange,
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  if (isEditing)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: PulseColors.red,
                      ),
                      onPressed: () async {
                        // 1. Показываем окно подтверждения и ждем ответа
                        final bool confirm = await ConfirmDialog.show(
                          context,
                          title: "Удалить счет?",
                          content:
                              "Это действие необратимо. Все транзакции этого счета также будут удалены.",
                        );

                        // 2. Если пользователь нажал "Удалить" (true)
                        if (confirm && mounted) {
                          // Выполняем удаление
                          context.read<WalletProvider>().deleteAccount(
                            widget.account!.id,
                          );
                          // Закрываем сам диалог настроек
                          Navigator.pop(context);
                        }
                      },
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "ОТМЕНА",
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(isEditing ? "СОХРАНИТЬ" : "СОЗДАТЬ"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Вспомогательный виджет для красивого свитча
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required Color activeColor,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white38, fontSize: 11),
      ),
      value: value,
      activeColor: activeColor,
      onChanged: onChanged,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.white38),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000);
  }
}
