import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/ui_kit/pulse_button.dart';
import '../../../../../../core/theme/pulse_theme.dart';
import '../../../presentation/wallet_provider.dart';

class DebtSyncConfirmationDialog extends StatefulWidget {
  final double amount;
  final bool isOweMe; // true = Я дал в долг (Расход), false = Я взял (Доход)

  const DebtSyncConfirmationDialog({
    super.key,
    required this.amount,
    required this.isOweMe,
  });

  @override
  State<DebtSyncConfirmationDialog> createState() =>
      _DebtSyncConfirmationDialogState();
}

class _DebtSyncConfirmationDialogState
    extends State<DebtSyncConfirmationDialog> {
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    final accounts = context.read<WalletProvider>().accounts;
    if (accounts.isNotEmpty) {
      _selectedAccountId = accounts.first.id;
    }
  }

  void _confirm() {
    Navigator.pop(context, _selectedAccountId);
  }

  void _skip() {
    Navigator.pop(context, null); // null означает "не синхронизировать"
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();
    final accounts = provider.accounts;

    // Текст зависит от типа долга
    final title = widget.isOweMe ? "Списать со счета?" : "Зачислить на счет?";
    final subtitle = widget.isOweMe
        ? "Деньги уйдут с выбранного счета"
        : "Деньги придут на выбранный счет";
    final color = widget.isOweMe ? PulseColors.red : PulseColors.green;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: const Color(0xFF1E202C).withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sync_alt, size: 48, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 24),

              if (accounts.isEmpty)
                const Text(
                  "Нет доступных счетов",
                  style: TextStyle(color: Colors.red),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedAccountId,
                      dropdownColor: const Color(0xFF2C2E3E),
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white54,
                      ),
                      items: accounts.map((acc) {
                        return DropdownMenuItem(
                          value: acc.id,
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                // Парсим цвет или дефолт
                                color: Color(
                                  int.tryParse(
                                            acc.colorHex.substring(1, 7),
                                            radix: 16,
                                          ) !=
                                          null
                                      ? int.parse(
                                              acc.colorHex.substring(1, 7),
                                              radix: 16,
                                            ) +
                                            0xFF000000
                                      : 0xFF808080,
                                ),
                                size: 10,
                              ),
                              const SizedBox(width: 10),
                              Text(acc.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedAccountId = v),
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _skip,
                      child: const Text(
                        "Пропустить",
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PulseButton(
                      text: "ОК",
                      color: color,
                      onPressed: _confirm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
