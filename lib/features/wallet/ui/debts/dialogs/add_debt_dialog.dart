import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/database/app_database.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/theme/pulse_theme.dart';
import '../../../../../core/ui_kit/pulse_button.dart';
import '../../../../../core/ui_kit/pulse_text_field.dart';
import '../../../../../core/ui_kit/pulse_large_number_input.dart';
import '../../../../../core/ui_kit/pulse_pickers.dart';

class AddDebtDialog extends StatefulWidget {
  final Debt? debt; // Если не null -> Режим редактирования

  const AddDebtDialog({super.key, this.debt});

  @override
  State<AddDebtDialog> createState() => _AddDebtDialogState();
}

class _AddDebtDialogState extends State<AddDebtDialog> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _rateCtrl =
      TextEditingController(); // Используется и для % и для Фикс суммы
  final _penaltyCtrl = TextEditingController();

  bool _isOweMe = true;

  // Срок
  bool _hasDueDate = false;
  DateTime _startDate = DateTime.now();
  DateTime? _dueDate;

  // Проценты / Начисления
  bool _hasInterest = false;
  String _interestType = 'percent'; // 'percent' или 'fixed'
  String _interestPeriod = 'month';

  // Штрафы
  bool _hasPenalty = false;
  String _penaltyType = 'fixed';

  @override
  void initState() {
    super.initState();

    // --- ЛОГИКА ЗАПОЛНЕНИЯ ПРИ РЕДАКТИРОВАНИИ ---
    if (widget.debt != null) {
      final d = widget.debt!;
      _nameCtrl.text = d.name;
      _amountCtrl.text = (d.amount.toDouble() / 100).toStringAsFixed(0);
      _isOweMe = d.isOweMe;

      _startDate = d.startDate;
      _dueDate = d.dueDate;
      _hasDueDate = d.dueDate != null;

      _hasInterest = d.interestType != 'none';
      if (_hasInterest) {
        _interestType = d.interestType; // 'percent' или 'fixed'
        _interestPeriod = d.interestPeriod ?? 'month';
        // Если тип fixed, то в rate лежит сумма, иначе процент
        _rateCtrl.text = d.interestRate.toStringAsFixed(
          d.interestType == 'fixed' ? 0 : 1,
        );
      }

      _hasPenalty = d.penaltyType != 'none';
      if (_hasPenalty) {
        _penaltyType = d.penaltyType;
        _penaltyCtrl.text = d.penaltyRate.toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _rateCtrl.dispose();
    _penaltyCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameCtrl.text.isEmpty || _amountCtrl.text.isEmpty) return;

    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    final rateOrFixed =
        double.tryParse(_rateCtrl.text.replaceAll(',', '.')) ?? 0;
    final penalty =
        double.tryParse(_penaltyCtrl.text.replaceAll(',', '.')) ?? 0;

    final dao = sl<AppDatabase>().debtsDao;

    // Подготовка объекта (Companion)
    final debtData = DebtsCompanion(
      id: drift.Value(
        widget.debt?.id ?? const Uuid().v4(),
      ), // ID старый или новый
      name: drift.Value(_nameCtrl.text),
      amount: drift.Value(BigInt.from((amount * 100).round())),
      isOweMe: drift.Value(_isOweMe),
      startDate: drift.Value(_startDate),
      dueDate: drift.Value(_hasDueDate ? _dueDate : null),

      // Логика процентов (Фикс или %)
      interestType: drift.Value(_hasInterest ? _interestType : 'none'),
      interestPeriod: drift.Value(_hasInterest ? _interestPeriod : null),
      interestRate: drift.Value(_hasInterest ? rateOrFixed : 0.0),

      // Логика штрафов
      penaltyType: drift.Value(_hasPenalty ? _penaltyType : 'none'),
      penaltyRate: drift.Value(_hasPenalty ? penalty : 0.0),
    );

    if (widget.debt != null) {
      // ОБНОВЛЕНИЕ
      // Нам нужно преобразовать Companion обратно в DataClass для update,
      // либо использовать update(debts).replace(...), но update принимает DataClass.
      // Проще всего использовать delete + create или custom update.
      // Но правильный путь в Drift для update - это использовать Companion внутри update statement.
      // Однако наш DebtsDao.updateDebt принимает (Debt debt).
      // Давай создадим Debt объект вручную для обновления:

      final updatedDebt = Debt(
        id: widget.debt!.id,
        name: _nameCtrl.text,
        amount: BigInt.from((amount * 100).round()),
        isOweMe: _isOweMe,
        startDate: _startDate,
        dueDate: _hasDueDate ? _dueDate : null,
        interestType: _hasInterest ? _interestType : 'none',
        interestPeriod: _hasInterest ? _interestPeriod : null,
        interestRate: _hasInterest ? rateOrFixed : 0.0,
        penaltyType: _hasPenalty ? _penaltyType : 'none',
        penaltyPeriod: null, // Пока не используем период для штрафа в UI
        penaltyRate: _hasPenalty ? penalty : 0.0,
        isClosed: widget.debt!.isClosed,
        closedDate: widget.debt!.closedDate,
      );

      dao.updateDebt(updatedDebt);
    } else {
      // СОЗДАНИЕ
      dao.createDebt(debtData);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _isOweMe ? PulseColors.green : PulseColors.red;
    final isEditing = widget.debt != null;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: const Color(0xFF1E202C).withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEditing ? "РЕДАКТИРОВАНИЕ" : "НОВЫЙ ДОЛГ",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              _buildTypeSwitcher(),
              const SizedBox(height: 24),

              PulseTextField(
                controller: _nameCtrl,
                label: "Имя / Контакт",
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
              PulseLargeNumberInput(
                controller: _amountCtrl,
                color: themeColor,
                suffix: "₽",
              ),

              const SizedBox(height: 24),

              // --- СРОКИ ---
              _buildSwitchTile(
                title: "Указать срок возврата",
                value: _hasDueDate,
                color: themeColor,
                onChanged: (v) => setState(() {
                  _hasDueDate = v;
                  if (v && _dueDate == null) {
                    _dueDate = DateTime.now().add(const Duration(days: 7));
                  }
                }),
              ),
              if (_hasDueDate) ...[
                const SizedBox(height: 10),
                _buildDateSelector(context),
              ],

              const SizedBox(height: 10),

              // --- ПРОЦЕНТЫ / ФИКС ---
              _buildSwitchTile(
                title: "Начислять сверху",
                value: _hasInterest,
                color: PulseColors.orange,
                onChanged: (v) => setState(() => _hasInterest = v),
              ),

              if (_hasInterest) ...[
                const SizedBox(height: 10),
                // Выбор типа начисления
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _interestTypeBtn("Процент %", 'percent'),
                      _interestTypeBtn("Фикс ₽", 'fixed'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: PulseTextField(
                        controller: _rateCtrl,
                        label: _interestType == 'percent'
                            ? "Ставка (%)"
                            : "Сумма (₽)",
                        type: TextInputType.number,
                      ),
                    ),
                    if (_interestType == 'percent') ...[
                      const SizedBox(width: 10),
                      _buildDropdown(
                        value: _interestPeriod,
                        items: {
                          'day': 'В день',
                          'week': 'В неделю',
                          'month': 'В мес.',
                          'year': 'В год',
                        },
                        onChanged: (v) => setState(() => _interestPeriod = v!),
                      ),
                    ] else ...[
                      // Для фиксы период не нужен (просто "Сверху")
                      const SizedBox(width: 10),
                      const Text(
                        "всего",
                        style: TextStyle(color: Colors.white38),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ],
                ),
              ],

              // --- ШТРАФЫ ---
              if (_hasDueDate) ...[
                const SizedBox(height: 10),
                _buildSwitchTile(
                  title: "Штраф за просрочку",
                  value: _hasPenalty,
                  color: PulseColors.red,
                  onChanged: (v) => setState(() => _hasPenalty = v),
                ),
                if (_hasPenalty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: PulseTextField(
                          controller: _penaltyCtrl,
                          label: "Штраф",
                          type: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildDropdown(
                        value: _penaltyType,
                        items: {'fixed': 'Фикс. ₽', 'percent': '% от долга'},
                        onChanged: (v) => setState(() => _penaltyType = v!),
                      ),
                    ],
                  ),
                ],
              ],

              const SizedBox(height: 32),
              PulseButton(
                text: "СОХРАНИТЬ",
                color: themeColor,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPERS ---

  Widget _interestTypeBtn(String text, String value) {
    final isSelected = _interestType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _interestType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? PulseColors.orange.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? PulseColors.orange : Colors.white38,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _typeBtn("Мне должны", true, PulseColors.green),
          _typeBtn("Я должен", false, PulseColors.red),
        ],
      ),
    );
  }

  Widget _typeBtn(String text, bool value, Color color) {
    final isSelected = _isOweMe == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isOweMe = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? color : Colors.white38,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      value: value,
      onChanged: onChanged,
      activeTrackColor: color,
      activeColor: Colors.white,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    final daysLeft = _dueDate!.difference(DateTime.now()).inDays;
    return GestureDetector(
      onTap: () async {
        final d = await PulsePickers.pickDateTime(
          context,
          initialDate: _dueDate!,
        );
        if (d != null) setState(() => _dueDate = d);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.white54,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('d MMMM y', 'ru').format(_dueDate!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              daysLeft < 0 ? "Просрочено" : "$daysLeft дн.",
              style: TextStyle(
                color: daysLeft < 0 ? PulseColors.red : PulseColors.primary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF2C2E3E),
          style: const TextStyle(color: Colors.white),
          items: items.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
