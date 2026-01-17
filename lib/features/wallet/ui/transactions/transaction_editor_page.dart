import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pulseos/core/ui_kit/pulse_pickers.dart';
import '../../../../core/ui_kit/pulse_overlays.dart';
import '../../../../core/ui_kit/pulse_page.dart';
import '../../../../core/ui_kit/pulse_buttons.dart';
import '../../../../core/ui_kit/pulse_large_number_input.dart';
import '../../../../core/theme/pulse_theme.dart';
import '../../presentation/wallet_provider.dart';
import 'editor_components.dart';

class TransactionEditorPage extends StatefulWidget {
  const TransactionEditorPage({super.key});

  @override
  State<TransactionEditorPage> createState() => _TransactionEditorPageState();
}

class _TransactionEditorPageState extends State<TransactionEditorPage> {
  // --- 1. ПРАВИЛЬНЫЕ ПЕРЕМЕННЫЕ СОСТОЯНИЯ ---
  String _type = 'expense';
  DateTime _selectedDate = DateTime.now();

  // Храним ID счетов, а не просто названия
  String? _selectedFromAccountId;
  String? _selectedToAccountId;

  final _amountCtrl = TextEditingController();
  final _storeCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    // --- 2. УСТАНОВКА СЧЕТА ПО УМОЛЧАНИЮ ---
    // Выполняем после отрисовки кадра, чтобы провайдер был доступен
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wallet = context.read<WalletProvider>();
      if (wallet.accounts.isNotEmpty) {
        // Ищем карту, помеченную как "Основная", иначе берем первую
        final mainAccount = wallet.accounts.firstWhere(
          (a) => a.isMain,
          orElse: () => wallet.accounts.first,
        );
        setState(() {
          _selectedFromAccountId = mainAccount.id;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getTypeColor();

    return PulsePage(
      title: "Операция",
      subtitle: _getTypeSubtitle(),
      accentColor: themeColor,
      showBackButton: true,

      // Кнопка скана
      actions: [
        GlassCircleButton(
          icon: Icons.qr_code_scanner,
          onTap: () {
            HapticFeedback.mediumImpact();
          },
        ),
      ],

      body: Column(
        children: [
          const SizedBox(height: 10),

          // 1. ТИП ОПЕРАЦИИ
          TransactionTypeSelector(
            currentType: _type,
            onTypeChanged: (val) => setState(() => _type = val),
          ),

          const SizedBox(height: 30),

          // 2. СУММА
          PulseLargeNumberInput(controller: _amountCtrl, color: themeColor),

          const SizedBox(height: 30),

          // 3. ОСНОВНЫЕ ПАРАМЕТРЫ
          EditorGlassTile(
            label: "ДАТА И ВРЕМЯ",
            value: DateFormat('d MMMM, HH:mm', 'ru').format(_selectedDate),
            icon: Icons.calendar_today,
            color: PulseColors.blue,
            onTap: () async {
              final DateTime? picked = await PulsePickers.pickDateTime(
                context,
                initialDate: _selectedDate,
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
          const SizedBox(height: 10),

          AccountPickerSection(
            type: _type,
            selectedFromId: _selectedFromAccountId,
            selectedToId: _selectedToAccountId,
            onFromChanged: (id) => setState(() => _selectedFromAccountId = id),
            onToChanged: (id) => setState(() => _selectedToAccountId = id),
          ),

          // Категорию пока оставим как есть, её сделаем следующим шагом
          if (_type != 'transfer') ...[
            const SizedBox(height: 10),
            EditorGlassTile(
              label: "КАТЕГОРИЯ",
              value: "Выбрать категорию", // Тут будет логика позже
              icon: Icons.category,
              color: PulseColors.yellow,
              onTap: () {
                PulseOverlays.showComingSoon(
                  context,
                  featureName: "Выбор категорий",
                );
              },
            ),
          ],

          const SizedBox(height: 20),

          // 4. ДЕТАЛИ
          EditorInput(
            hint: "Магазин / Организация",
            icon: Icons.storefront,
            controller: _storeCtrl,
          ),
          const SizedBox(height: 10),
          EditorInput(
            hint: "Заметка к операции",
            icon: Icons.notes,
            controller: _noteCtrl,
          ),

          const SizedBox(height: 30),

          // 5. ПОЗИЦИИ (Items)
          _buildItemsSection(),

          const SizedBox(height: 30),

          // КНОПКА СОХРАНИТЬ
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
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
    );
  }

  // МЕТОД СОХРАНЕНИЯ (ЗАГОТОВКА)
  void _saveTransaction() {
    if (_amountCtrl.text.isEmpty || _selectedFromAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Введите сумму и выберите счет")),
      );
      return;
    }

    // Пока просто закрываем, скоро напишем вызов провайдера
    HapticFeedback.heavyImpact();
    Navigator.pop(context);
  }

  Color _getTypeColor() {
    switch (_type) {
      case 'income':
        return PulseColors.green;
      case 'transfer':
        return PulseColors.blue;
      case 'transfer_person':
        return PulseColors.purple;
      default:
        return PulseColors.red;
    }
  }

  String _getTypeSubtitle() {
    switch (_type) {
      case 'income':
        return "ДОХОД";
      case 'transfer':
        return "ПЕРЕВОД";
      case 'transfer_person':
        return "ЛЮДЯМ";
      default:
        return "РАСХОД";
    }
  }

  Widget _buildItemsSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "ПОЗИЦИИ ЧЕКА",
              style: TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: const Icon(Icons.add_circle, color: PulseColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Пустой список
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: const Center(
            child: Text(
              "Список пуст. Добавьте товары вручную или сканируйте чек.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}
