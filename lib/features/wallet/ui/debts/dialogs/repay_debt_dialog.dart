import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../../core/database/app_database.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/theme/pulse_theme.dart';
import '../../../../../core/ui_kit/pulse_button.dart';
import '../../../../../core/ui_kit/pulse_large_number_input.dart';
import '../../../presentation/wallet_provider.dart';

class RepayDebtDialog extends StatefulWidget {
  final Debt debt;

  const RepayDebtDialog({super.key, required this.debt});

  @override
  State<RepayDebtDialog> createState() => _RepayDebtDialogState();
}

class _RepayDebtDialogState extends State<RepayDebtDialog> {
  final _amountCtrl = TextEditingController();

  // Для синхронизации с кошельком
  bool _syncWithWallet = true;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    // По умолчанию предлагаем вернуть всю сумму
    final currentAmount = widget.debt.amount.toDouble() / 100;
    _amountCtrl.text = currentAmount.toStringAsFixed(0);

    // Выбираем первый счет по умолчанию
    final wallet = context.read<WalletProvider>();
    if (wallet.accounts.isNotEmpty) {
      _selectedAccountId = wallet.accounts.first.id;
    }
  }

  Future<void> _save() async {
    final enteredAmount =
        double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    if (enteredAmount <= 0) return;

    final db = sl<AppDatabase>();
    final walletProvider = context.read<WalletProvider>();
    final currentBigInt = widget.debt.amount;
    final repayBigInt = BigInt.from((enteredAmount * 100).round());

    // 1. Обновляем Долг
    // Если вернули всё или больше -> закрываем
    // Иначе -> уменьшаем сумму
    bool isFullRepayment = repayBigInt >= currentBigInt;

    final updatedDebt = widget.debt.copyWith(
      amount: isFullRepayment ? BigInt.zero : (currentBigInt - repayBigInt),
      isClosed: isFullRepayment,
      closedDate: isFullRepayment
          ? drift.Value(DateTime.now())
          : const drift.Value(null),
    );

    await db.debtsDao.updateDebt(updatedDebt);

    // 2. Создаем транзакцию в кошельке (если выбрано)
    if (_syncWithWallet && _selectedAccountId != null) {
      // Определяем тип:
      // Если "Мне должны" (isOweMe) и мне вернули -> Это Доход (Income)
      // Если "Я должен" (!isOweMe) и я вернул -> Это Расход (Expense)
      final type = widget.debt.isOweMe ? 'income' : 'expense';

      // Ищем или создаем категорию "Долги"
      // (Для простоты пока просто передадим название, но лучше найти ID категории)

      await walletProvider.addTransaction(
        amount: enteredAmount,
        type: type,
        accountId: _selectedAccountId!,
        note: "Возврат долга: ${widget.debt.name}",
        date: DateTime.now(),
        // Можно добавить тег или категорию "Долги" здесь
      );
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFullRepayment ? "Долг закрыт! 🎉" : "Частично погашено",
          ),
          backgroundColor: PulseColors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<WalletProvider>().accounts;

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
              const Text(
                "ПОГАШЕНИЕ",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              PulseLargeNumberInput(
                controller: _amountCtrl,
                color: PulseColors.green,
                suffix: "₽",
              ),
              const SizedBox(height: 24),

              // Настройки синхронизации
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        "Провести в кошельке",
                        style: TextStyle(color: Colors.white),
                      ),
                      value: _syncWithWallet,
                      activeTrackColor: PulseColors.green,
                      activeColor: Colors.white,
                      onChanged: (v) => setState(() => _syncWithWallet = v),
                    ),
                    if (_syncWithWallet && accounts.isNotEmpty)
                      _buildAccountSelector(accounts),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              PulseButton(
                text: "ВНЕСТИ",
                color: PulseColors.green,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSelector(List<Account> accounts) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final acc = accounts[index];
          final isSelected = acc.id == _selectedAccountId;
          // Парсим цвет
          Color accColor;
          try {
            accColor = Color(
              int.parse(acc.colorHex.substring(1, 7), radix: 16) + 0xFF000000,
            );
          } catch (e) {
            accColor = Colors.grey;
          }

          return GestureDetector(
            onTap: () => setState(() => _selectedAccountId = acc.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? accColor.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? accColor : Colors.white10,
                  width: isSelected ? 2 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                acc.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
