import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../../core/database/app_database.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/theme/pulse_theme.dart';
import '../../../../../core/ui_kit/pulse_button.dart';
import '../../../../../core/ui_kit/pulse_large_number_input.dart';
import '../../../../../core/ui_kit/pulse_pickers.dart';
import '../../../../../core/ui_kit/pulse_text_field.dart';
import '../../../../../core/utils/icon_helper.dart';
import '../../../presentation/wallet_provider.dart';

class AddPlannedDialog extends StatefulWidget {
  final DateTime? initialDate;
  const AddPlannedDialog({super.key, this.initialDate});

  @override
  State<AddPlannedDialog> createState() => _AddPlannedDialogState();
}

class _AddPlannedDialogState extends State<AddPlannedDialog> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _intervalCtrl = TextEditingController(text: "1");

  // Состояние формы
  String _type = 'expense'; // expense | income
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId;
  String? _selectedAccountId;

  // Рекурсия
  bool _isRecurring = false;
  String _recurrenceType = 'monthly'; // daily, weekly, monthly, yearly

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) _selectedDate = widget.initialDate!;

    // Автовыбор первого счета
    final wallet = context.read<WalletProvider>();
    if (wallet.accounts.isNotEmpty)
      _selectedAccountId = wallet.accounts.first.id;
  }

  void _save() {
    if (_nameCtrl.text.isEmpty || _amountCtrl.text.isEmpty) return;

    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    final interval = int.tryParse(_intervalCtrl.text) ?? 1;

    final entry = PlannedTransactionsCompanion.insert(
      id: const Uuid().v4(),
      name: _nameCtrl.text,
      amount: BigInt.from((amount * 100).round()),
      type: _type,
      date: _selectedDate,
      accountId: drift.Value(_selectedAccountId),
      categoryId: drift.Value(_selectedCategoryId),
      isRecurring: drift.Value(_isRecurring),
      recurrenceType: drift.Value(_isRecurring ? _recurrenceType : null),
      recurrenceInterval: drift.Value(_isRecurring ? interval : null),
    );

    sl<AppDatabase>().planningDao.createPlanned(entry);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _type == 'expense' ? PulseColors.red : PulseColors.green;
    final wallet = context.watch<WalletProvider>();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: const Color(0xFF1E202C).withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        insetPadding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. ПЕРЕКЛЮЧАТЕЛЬ ТИПА
              _buildTypeSwitcher(),
              const SizedBox(height: 24),

              // 2. НАЗВАНИЕ И СУММА
              PulseTextField(
                controller: _nameCtrl,
                label: "Название",
                icon: Icons.edit,
              ),
              const SizedBox(height: 16),
              PulseLargeNumberInput(controller: _amountCtrl, color: themeColor),
              const SizedBox(height: 24),

              // 3. ДАТА, СЧЕТ И КАТЕГОРИЯ
              _buildPickerTile(
                label: "Дата",
                value: DateFormat('d MMMM y', 'ru').format(_selectedDate),
                icon: Icons.calendar_today,
                onTap: () async {
                  final d = await PulsePickers.pickDateTime(
                    context,
                    initialDate: _selectedDate,
                  );
                  if (d != null) setState(() => _selectedDate = d);
                },
              ),
              const SizedBox(height: 12),
              _buildAccountPicker(wallet.accounts),
              const SizedBox(height: 12),
              _buildCategoryPicker(wallet.categories),

              const SizedBox(height: 20),

              // 4. ПОВТОРЫ (Рекурсия)
              _buildRecurringSection(themeColor),

              const SizedBox(height: 16),
              PulseTextField(
                controller: _noteCtrl,
                label: "Заметка",
                icon: Icons.notes,
              ),

              const SizedBox(height: 32),

              // 5. КНОПКИ
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "ОТМЕНА",
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PulseButton(
                      text: "ДОБАВИТЬ",
                      color: themeColor,
                      onPressed: _save,
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

  // --- Вспомогательные методы построения интерфейса ---

  Widget _buildTypeSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _typeBtn("Расход", 'expense', PulseColors.red),
          _typeBtn("Доход", 'income', PulseColors.green),
        ],
      ),
    );
  }

  Widget _typeBtn(String label, String val, Color color) {
    bool isSel = _type == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = val),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSel ? color.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSel ? color.withValues(alpha: 0.5) : Colors.transparent,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSel ? color : Colors.white38,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickerTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.white30),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 16, color: Colors.white10),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountPicker(List<Account> accounts) {
    final acc = accounts.firstWhere(
      (a) => a.id == _selectedAccountId,
      orElse: () => accounts.first,
    );
    return _buildPickerTile(
      label: "Счет",
      value: acc.name,
      icon: Icons.account_balance_wallet_outlined,
      onTap: () {
        // Здесь можно вызвать шторку выбора счета из транзакций
      },
    );
  }

  Widget _buildCategoryPicker(List<CategoryWithTags> categories) {
    final cat = categories.firstWhere(
      (c) => c.category.id == _selectedCategoryId,
      orElse: () => CategoryWithTags(
        Category(
          id: '',
          name: 'Выбрать...',
          colorHex: '#808080',
          moduleType: 'finance',
        ),
        [],
      ),
    );
    return _buildPickerTile(
      label: "Категория",
      value: cat.category.name,
      icon: getIcon(cat.category.iconKey ?? 'category'),
      onTap: () {
        // Здесь можно вызвать шторку выбора категорий
      },
    );
  }

  Widget _buildRecurringSection(Color color) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text(
            "Повторяющееся событие",
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          value: _isRecurring,
          activeTrackColor: color,
          onChanged: (v) => setState(() => _isRecurring = v),
          contentPadding: EdgeInsets.zero,
        ),
        if (_isRecurring) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _buildDropdown(
                  label: "Как часто",
                  value: _recurrenceType,
                  items: {
                    'daily': 'Ежедневно',
                    'weekly': 'Еженедельно',
                    'monthly': 'Ежемесячно',
                    'yearly': 'Ежегодно',
                  },
                  onChanged: (v) => setState(() => _recurrenceType = v!),
                ),
                const SizedBox(height: 12),
                PulseTextField(
                  controller: _intervalCtrl,
                  label: "Интервал (каждый...)",
                  type: TextInputType.number,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF2C2E3E),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        border: InputBorder.none,
      ),
      items: items.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
