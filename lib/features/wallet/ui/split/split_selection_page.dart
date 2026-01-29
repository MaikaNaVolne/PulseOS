import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/pulse_theme.dart';
import '../../presentation/wallet_provider.dart'; // TransactionItemDto

class SplitSelectionPage extends StatefulWidget {
  final List<TransactionItemDto> items;
  final Function(List<TransactionItemDto>) onSave;

  const SplitSelectionPage({
    super.key,
    required this.items,
    required this.onSave,
  });

  @override
  State<SplitSelectionPage> createState() => _SplitSelectionPageState();
}

class _SplitSelectionPageState extends State<SplitSelectionPage> {
  // Локальная копия для редактирования
  late List<TransactionItemDto> _items;
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    // Создаем глубокую копию списка, чтобы не мутировать исходные данные до сохранения
    _items = widget.items
        .map(
          (i) => TransactionItemDto(
            name: i.name,
            price: i.price,
            quantity: i.quantity,
            categoryId: i.categoryId,
            tags: List.from(i.tags),
          ),
        )
        .toList();
  }

  void _toggleSelection(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _selectAll() {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_selectedIndices.length == _items.length) {
        _selectedIndices.clear();
      } else {
        _selectedIndices.addAll(List.generate(_items.length, (i) => i));
      }
    });
  }

  void _assignCategory() {
    if (_selectedIndices.isEmpty) return;

    final provider = context.read<WalletProvider>();
    final categories = provider.categories; // CategoryWithTags

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Color(0xFF1E202C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 15),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "Выберите категорию для выделенных",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (ctx, i) {
                    final catItem = categories[i];
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _hexToColor(
                            catItem.category.colorHex,
                          ).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.circle,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        catItem.category.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        setState(() {
                          for (var idx in _selectedIndices) {
                            _items[idx].categoryId = catItem.category.id;
                          }
                          _selectedIndices.clear();
                        });
                        Navigator.pop(ctx);
                        HapticFeedback.mediumImpact();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    widget.onSave(_items);
    Navigator.pop(context);
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseColors.background,
      appBar: AppBar(
        title: Text("Сплит чека (${_selectedIndices.length})"),
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _selectAll,
            child: Text(
              _selectedIndices.length == _items.length ? "Снять все" : "Все",
              style: const TextStyle(color: PulseColors.blue),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final isSelected = _selectedIndices.contains(index);

                // Получаем имя категории для отображения
                String? catName;
                if (item.categoryId != null) {
                  try {
                    final catData = context
                        .read<WalletProvider>()
                        .categories
                        .firstWhere((c) => c.category.id == item.categoryId);
                    catName = catData.category.name;
                  } catch (_) {}
                }

                return GestureDetector(
                  onTap: () => _toggleSelection(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? PulseColors.blue.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? PulseColors.blue
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isSelected ? PulseColors.blue : Colors.white24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (catName != null)
                                Text(
                                  catName,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: PulseColors.orange,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          "${(item.price * item.quantity).toStringAsFixed(0)} ₽",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Панель действий
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1E202C),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: _selectedIndices.isNotEmpty
                  ? Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.category),
                              label: const Text("Категория"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PulseColors.purple,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _assignCategory,
                            ),
                          ),
                        ),
                        // Место для кнопки "В долг" (в будущем)
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PulseColors.green,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text(
                          "ГОТОВО",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
