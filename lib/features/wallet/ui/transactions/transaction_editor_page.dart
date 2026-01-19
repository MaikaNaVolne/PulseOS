import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pulseos/core/ui_kit/pulse_pickers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/ui_kit/pulse_page.dart';
import '../../../../core/ui_kit/pulse_buttons.dart';
import '../../../../core/ui_kit/pulse_large_number_input.dart';
import '../../../../core/theme/pulse_theme.dart';
import '../../presentation/wallet_provider.dart';
import 'dialog/add_item_dialog.dart';
import 'editor_components.dart';

class TransactionEditorPage extends StatefulWidget {
  const TransactionEditorPage({super.key});

  @override
  State<TransactionEditorPage> createState() => _TransactionEditorPageState();
}

class _TransactionEditorPageState extends State<TransactionEditorPage> {
  // --- ДОБАВИТЬ ЭТИ ПЕРЕМЕННЫЕ ---
  String _type = 'expense';
  DateTime _selectedDate = DateTime.now();
  String? _selectedFromAccountId;
  String? _selectedToAccountId;
  String? _selectedCategoryId;
  String? _activeTagForBatching;

  // Список товаров в чеке
  List<TransactionItemDto> _items = [];

  final _amountCtrl = TextEditingController();
  final _storeCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  final _recipientCtrl = TextEditingController();

  // --- ДОБАВИТЬ МЕТОД ДОБАВЛЕНИЯ ТОВАРА ---
  void _addItem() async {
    // Диалог теперь возвращает DTO
    final newItem = await showDialog<TransactionItemDto>(
      context: context,
      builder: (_) => const AddItemDialog(),
    );

    if (newItem != null) {
      setState(() {
        _items.add(newItem); // Просто добавляем, конвертация не нужна
        _recalculateTotal();
      });
    }
  }

  // --- ДОБАВИТЬ МЕТОД ПЕРЕСЧЕТА СУММЫ ---
  void _recalculateTotal() {
    if (_items.isEmpty) return;

    double totalRubles = 0;
    for (var item in _items) {
      // Цена в DTO уже в рублях. Никакого деления на 100!
      totalRubles += item.price * item.quantity;
    }

    setState(() {
      // Округляем до 2 знаков после запятой, чтобы не было 199.9900000004
      _amountCtrl.text = totalRubles.toStringAsFixed(2);

      if (_amountCtrl.text.endsWith(".00")) {
        _amountCtrl.text = _amountCtrl.text.substring(
          0,
          _amountCtrl.text.length - 3,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getTypeColor();
    final wallet = context.watch<WalletProvider>();
    if (_selectedFromAccountId == null && wallet.accounts.isNotEmpty) {
      final mainAccount = wallet.accounts.firstWhere(
        (a) => a.isMain,
        orElse: () => wallet.accounts.first,
      );
      // Важно: делаем это в микротаске, чтобы не сломать build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedFromAccountId = mainAccount.id;
        });
      });
    }

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

          // Категория
          if (_type != 'transfer') ...[
            const SizedBox(height: 10),
            CategoryPickerSection(
              selectedCategoryId: _selectedCategoryId,
              onCategoryChanged: (id) {
                setState(() => _selectedCategoryId = id);
              },
            ),
          ],

          // ТЕГИ (Показываем только если категория выбрана и не перевод)
          if (_type != 'transfer' && _selectedCategoryId != null) ...[
            const SizedBox(height: 12),
            _buildTagsList(context),
          ],

          const SizedBox(height: 20),

          // ДЛЯ ПЕРЕВОДА ЛЮДЯМ
          if (_type == 'transfer_person') ...[
            const SizedBox(height: 12),
            EditorInput(
              hint: "Кому (Имя или контакт)",
              icon: Icons.person_outline,
              controller: _recipientCtrl,
            ),
          ],

          const SizedBox(height: 20),

          // 4. ДЕТАЛИ
          if (_type != 'transfer' && _type != 'transfer_person') ...[
            EditorInput(
              hint: "Магазин / Организация",
              icon: Icons.storefront,
              controller: _storeCtrl,
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          EditorInput(
            hint: "Заметка к операции",
            icon: Icons.notes,
            controller: _noteCtrl,
          ),

          const SizedBox(height: 30),

          // 5. ПОЗИЦИИ (Items)
          if (_type != 'transfer') _buildItemsSection(),

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

  Widget _buildTagsList(BuildContext context) {
    final provider = context.read<WalletProvider>();
    // Ищем теги для выбранной категории
    final categoryData = provider.categories.firstWhere(
      (c) => c.category.id == _selectedCategoryId,
      orElse: () => CategoryWithTags(
        Category(
          id: 'temp',
          name: 'temp',
          iconKey: 'help',
          colorHex: '#808080',
          moduleType: '',
        ),
        [],
      ),
    );

    if (categoryData.tags.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categoryData.tags.length,
        itemBuilder: (context, index) {
          final tag = categoryData.tags[index];
          final isActive = _activeTagForBatching == tag;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                // Если нажали на уже активный - выключаем режим
                if (_activeTagForBatching == tag) {
                  _activeTagForBatching = null;
                } else {
                  // Иначе включаем режим для этого тега
                  _activeTagForBatching = tag;

                  // Показываем подсказку пользователю
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Нажимайте на товары, чтобы добавить тег '$tag'",
                      ),
                      backgroundColor: PulseColors.primary,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? PulseColors.primary.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? PulseColors.primary : Colors.white10,
                  width: isActive ? 1.5 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                tag,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // МЕТОД СОХРАНЕНИЯ (ЗАГОТОВКА)
  void _saveTransaction() async {
    // 1. Валидация
    if (_amountCtrl.text.isEmpty) {
      _showSnack("Введите сумму", isError: true);
      return;
    }
    if (_selectedFromAccountId == null) {
      _showSnack("Выберите счет списания", isError: true);
      return;
    }

    String? finalStoreName;

    if (_type == 'transfer_person') {
      // Если перевод человеку - берем из поля "Кому"
      finalStoreName = _recipientCtrl.text.isNotEmpty
          ? _recipientCtrl.text
          : null;
    } else {
      // Иначе берем из поля "Магазин"
      finalStoreName = _storeCtrl.text.isNotEmpty ? _storeCtrl.text : null;
    }

    HapticFeedback.mediumImpact();

    // Парсим сумму
    final double amount =
        double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0.0;

    // 2. Вызываем провайдер
    final provider = context.read<WalletProvider>();

    await provider.addTransaction(
      amount: amount,
      type: _type,
      accountId: _selectedFromAccountId!,
      toAccountId: _selectedToAccountId,
      categoryId: _selectedCategoryId,
      date: _selectedDate,
      storeName: finalStoreName,
      note: _noteCtrl.text.isNotEmpty ? _noteCtrl.text : null,

      // ИСПРАВЛЕНИЕ ЗДЕСЬ:
      items: _items
          .map(
            (i) => TransactionItemDto(
              name: i.name,
              // Переводим BigInt копейки назад в double рубли для DTO
              price: i.price.toDouble() / 100,
              quantity: i.quantity,
              categoryId: i.categoryId,
            ),
          )
          .toList(),
    );

    if (mounted) Navigator.pop(context);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? PulseColors.red : PulseColors.green,
      ),
    );
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
    final bool hasItems = _items.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- ЗАГОЛОВОК СЕКЦИИ ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  "ПОЗИЦИИ ЧЕКА",
                  style: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
                if (hasItems) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: PulseColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "${_items.length}",
                      style: const TextStyle(
                        color: PulseColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            // Кнопка добавить
            GestureDetector(
              onTap: _addItem,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: PulseColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: PulseColors.primary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // --- КОНТЕНТ (СПИСОК ИЛИ ЗАГЛУШКА) ---
        if (!hasItems)
          // СОСТОЯНИЕ: ПУСТО
          _buildEmptyPlaceholder()
        else
          // СОСТОЯНИЕ: СПИСОК ТОВАРОВ
          Column(
            children: _items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildItemCard(index, item);
            }).toList(),
          ),
      ],
    );
  }

  // Виджет пустой секции
  Widget _buildEmptyPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, color: Colors.white10, size: 32),
          SizedBox(height: 12),
          Text(
            "Список пуст. Добавьте товары вручную\nили сканируйте чек через QR.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white24, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  // Виджет карточки товара в списке
  Widget _buildItemCard(int index, TransactionItemDto item) {
    // 1. Конвертируем цену из копеек (BigInt) в рубли (double)
    final double priceRub = item.price;

    // 2. Считаем общую стоимость позиции (Цена x Кол-во)
    final double totalRub = priceRub * item.quantity;

    // 3. Форматируем для отображения (без лишних .0)
    final String priceStr = priceRub.toStringAsFixed(priceRub % 1 == 0 ? 0 : 2);
    final String qtyStr = item.quantity.toStringAsFixed(
      item.quantity % 1 == 0 ? 0 : 2,
    );
    final String totalStr = totalRub.toStringAsFixed(totalRub % 1 == 0 ? 0 : 2);

    // Проверяем, есть ли у товара активный тег (для подсветки)
    final bool hasActiveTag =
        _activeTagForBatching != null &&
        item.tags.contains(_activeTagForBatching);

    return GestureDetector(
      // ГЛАВНАЯ ЛОГИКА НАЖАТИЯ
      onTap: () {
        if (_activeTagForBatching != null) {
          // РЕЖИМ ТЕГИРОВАНИЯ
          HapticFeedback.lightImpact();
          setState(() {
            if (item.tags.contains(_activeTagForBatching)) {
              item.tags.remove(_activeTagForBatching);
            } else {
              item.tags.add(_activeTagForBatching!);
            }
          });
        } else {
          // ОБЫЧНЫЙ РЕЖИМ (РЕДАКТИРОВАНИЕ)
          _editItem(index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Подсвечиваем карточку, если мы в режиме тегирования и тег уже стоит
          color: hasActiveTag
              ? PulseColors.primary.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasActiveTag
                ? PulseColors.primary.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          // Завернули Row в Column, чтобы добавить теги снизу
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Инфо о товаре
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$qtyStr шт. x $priceStr ₽",
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Цена и Удаление
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "$totalStr ₽",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        // Удаление работает всегда, даже в режиме тегов
                        HapticFeedback.lightImpact();
                        setState(() {
                          _items.removeAt(index);
                          _recalculateTotal();
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: PulseColors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ОТОБРАЖЕНИЕ ТЕГОВ ТОВАРА
            if (item.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: item.tags
                    .map(
                      (t) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "#$t",
                          style: TextStyle(
                            fontSize: 10,
                            color: t == _activeTagForBatching
                                ? PulseColors.primary
                                : Colors.white54,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _editItem(int index) async {
    final item = _items[index];

    // Передаем DTO в диалог и ждем DTO обратно
    final editedItem = await showDialog<TransactionItemDto>(
      context: context,
      builder: (_) => AddItemDialog(item: item),
    );

    if (editedItem != null) {
      setState(() {
        _items[index] = editedItem; // Заменяем
        _recalculateTotal();
      });
    }
  }
}
