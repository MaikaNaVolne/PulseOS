import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../core/database/app_database.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/pulse_theme.dart';
import '../../../../core/ui_kit/pulse_text_field.dart';
import '../../../../core/ui_kit/pulse_pickers.dart';

class SleepEditorDialog extends StatefulWidget {
  final SleepEntry? entry; // Если есть - редактируем
  final String? initialType; // 'night' или 'nap'

  const SleepEditorDialog({super.key, this.entry, this.initialType});

  @override
  State<SleepEditorDialog> createState() => _SleepEditorDialogState();
}

class _SleepEditorDialogState extends State<SleepEditorDialog> {
  late DateTime _start;
  late DateTime _end;
  late String _type;

  double _quality = 7;
  double _wakeEase = 7;
  double _energy = 7;

  final _notesCtrl = TextEditingController();
  List<SleepFactor> _allFactors = [];
  final Set<String> _selectedFactorIds = {};

  @override
  void initState() {
    super.initState();
    _type = widget.entry?.sleepType ?? widget.initialType ?? 'night';

    if (widget.entry != null) {
      final e = widget.entry!;
      _start = e.startTime;
      _end = e.endTime;
      _quality = e.quality.toDouble();
      _wakeEase = e.wakeEase.toDouble();
      _energy = e.energyLevel.toDouble();
      _notesCtrl.text = e.note ?? "";
      _loadExistingFactors(e.id);
    } else {
      _end = DateTime.now();
      _start = _type == 'night'
          ? _end.subtract(const Duration(hours: 8))
          : _end.subtract(const Duration(minutes: 30));
    }
    _loadFactors();
  }

  void _loadFactors() async {
    final factors = await sl<AppDatabase>().sleepDao.getAllFactors();
    setState(() => _allFactors = factors);
  }

  void _loadExistingFactors(String id) async {
    final factors = await sl<AppDatabase>().sleepDao.getFactorsForSleep(id);
    setState(() {
      _selectedFactorIds.addAll(factors.map((f) => f.id));
    });
  }

  void _save() async {
    final dao = sl<AppDatabase>().sleepDao;
    final id = widget.entry?.id ?? const Uuid().v4();

    final companion = SleepEntriesCompanion.insert(
      id: id,
      startTime: _start,
      endTime: _end,
      quality: _quality.toInt(),
      wakeEase: _wakeEase.toInt(),
      energyLevel: _energy.toInt(),
      sleepType: drift.Value(_type),
      note: drift.Value(_notesCtrl.text),
    );

    if (widget.entry != null) {
      await dao.update(sl<AppDatabase>().sleepEntries).replace(companion);
      await dao.clearFactorLinks(id);
    } else {
      await dao.insertSleep(companion);
    }

    // Сохраняем связи с факторами
    for (var fId in _selectedFactorIds) {
      await dao.linkFactorToSleep(id, fId);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final duration = _end.difference(_start);
    final themeColor = _type == 'night'
        ? PulseColors.purple
        : PulseColors.orange;

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

              // 2. ВРЕМЯ (ОТ И ДО)
              _buildTimeRow(context),
              const SizedBox(height: 12),
              Text(
                "${duration.inHours}ч ${duration.inMinutes.remainder(60)}м",
                style: TextStyle(
                  color: themeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 24),

              // 3. СЛАЙДЕРЫ ОЦЕНКИ
              _buildMetricSlider(
                "Качество сна",
                _quality,
                PulseColors.purple,
                (v) => setState(() => _quality = v),
              ),
              _buildMetricSlider(
                "Легкость подъема",
                _wakeEase,
                PulseColors.orange,
                (v) => setState(() => _wakeEase = v),
              ),
              _buildMetricSlider(
                "Бодрость днем",
                _energy,
                PulseColors.primary,
                (v) => setState(() => _energy = v),
              ),

              const SizedBox(height: 24),

              // 4. ФАКТОРЫ (TAGS)
              if (_type == 'night') ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "ФАКТОРЫ",
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allFactors
                      .map(
                        (f) => _FactorChip(
                          factor: f,
                          isSelected: _selectedFactorIds.contains(f.id),
                          onTap: () => setState(() {
                            _selectedFactorIds.contains(f.id)
                                ? _selectedFactorIds.remove(f.id)
                                : _selectedFactorIds.add(f.id);
                          }),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
              ],

              // 5. ЗАМЕТКА
              PulseTextField(
                controller: _notesCtrl,
                label: "Заметка / Сны",
                icon: Icons.notes,
              ),

              const SizedBox(height: 32),

              // 6. КНОПКА
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
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

  // --- Вспомогательные виджеты ---

  Widget _buildTypeSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _typeBtn("Ночной", 'night', PulseColors.purple),
          _typeBtn("Дневной", 'nap', PulseColors.orange),
        ],
      ),
    );
  }

  Widget _typeBtn(String label, String val, Color color) {
    final isSel = _type == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = val;
          if (val == 'nap') _selectedFactorIds.clear();
        }),
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
              color: isSel ? Colors.white : Colors.white38,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _timeBtn("ЛЕГ", _start, () async {
            final d = await PulsePickers.pickDateTime(
              context,
              initialDate: _start,
            );
            if (d != null) setState(() => _start = d);
          }),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _timeBtn("ВСТАЛ", _end, () async {
            final d = await PulsePickers.pickDateTime(
              context,
              initialDate: _end,
            );
            if (d != null) setState(() => _end = d);
          }),
        ),
      ],
    );
  }

  Widget _timeBtn(String label, DateTime dt, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white24,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(dt),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              DateFormat('d MMM', 'ru').format(dt),
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSlider(
    String label,
    double val,
    Color color,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              "${val.toInt()}/10",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Slider(
          value: val,
          min: 1,
          max: 10,
          divisions: 9,
          activeColor: color,
          inactiveColor: Colors.white.withValues(alpha: 0.05),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _FactorChip extends StatelessWidget {
  final SleepFactor factor;
  final bool isSelected;
  final VoidCallback onTap;

  const _FactorChip({
    required this.factor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = factor.impactType == 'positive'
        ? PulseColors.primary
        : PulseColors.red;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.transparent),
        ),
        child: Text(
          factor.name,
          style: TextStyle(
            color: isSelected ? color : Colors.white38,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
