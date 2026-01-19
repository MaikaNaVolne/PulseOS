import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../../core/theme/pulse_theme.dart';
import '../../../presentation/wallet_provider.dart';

class AddItemDialog extends StatefulWidget {
  final TransactionItemDto? item;
  const AddItemDialog({super.key, this.item});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: "1");
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameCtrl.text = widget.item!.name;
      _priceCtrl.text = widget.item!.price.toString();
      _qtyCtrl.text = widget.item!.quantity.toString();
      _tags = List.from(widget.item!.tags);
    }
  }

  void _save() {
    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) return;

    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;
    final qty = double.tryParse(_qtyCtrl.text.replaceAll(',', '.')) ?? 1;

    final newItem = TransactionItemDto(
      // <--- Возвращаем DTO
      name: _nameCtrl.text,
      price: price,
      quantity: qty,
      categoryId: widget.item?.categoryId, // Сохраняем старую категорию
      tags: _tags, // Сохраняем теги
    );

    Navigator.pop(context, newItem);
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: const Color(0xFF1E202C).withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Позиция чека",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              _field(_nameCtrl, "Название", Icons.shopping_bag),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _priceCtrl,
                      "Цена",
                      Icons.attach_money,
                      isNum: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 80,
                    child: _field(
                      _qtyCtrl,
                      "Кол-во",
                      Icons.numbers,
                      isNum: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PulseColors.primary,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text(
                    "ДОБАВИТЬ",
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

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    bool isNum = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: c,
        keyboardType: isNum
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.white30, size: 20),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
