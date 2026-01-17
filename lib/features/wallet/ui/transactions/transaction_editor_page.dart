import 'package:flutter/material.dart';
import '../../../../core/ui_kit/pulse_page.dart';
import '../../../../core/theme/pulse_theme.dart';

class TransactionEditorPage extends StatefulWidget {
  const TransactionEditorPage({super.key});

  @override
  State<TransactionEditorPage> createState() => _TransactionEditorPageState();
}

class _TransactionEditorPageState extends State<TransactionEditorPage> {
  String _type = 'expense'; // expense, income, transfer

  @override
  Widget build(BuildContext context) {
    return PulsePage(
      title: "Новая запись",
      subtitle: _type == 'expense'
          ? "РАСХОД"
          : (_type == 'income' ? "ДОХОД" : "ПЕРЕВОД"),
      accentColor: _getColor(),
      showBackButton: true,

      // Кнопка скана чека
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: () {
            // TODO: Скан чека
          },
        ),
      ],

      body: Column(
        children: [
          // Тут будет переключатель типов
          const SizedBox(height: 20),
          _buildTypeSelector(),

          const SizedBox(height: 40),

          // Поле ввода суммы (Заглушка)
          const Text(
            "0 ₽",
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    if (_type == 'income') return PulseColors.yellow;
    if (_type == 'transfer') return PulseColors.blue;
    return PulseColors.red;
  }

  Widget _buildTypeSelector() {
    // Временный переключатель
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'expense', label: Text('Расход')),
        ButtonSegment(value: 'income', label: Text('Доход')),
        ButtonSegment(value: 'transfer', label: Text('Перевод')),
      ],
      selected: {_type},
      onSelectionChanged: (Set<String> newSelection) {
        setState(() {
          _type = newSelection.first;
        });
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return _getColor().withOpacity(0.2);
          }
          return Colors.transparent;
        }),
      ),
    );
  }
}
