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
import '../../data/tables/wallet_tables.dart';
import '../../presentation/wallet_provider.dart';
import 'dialog/add_item_dialog.dart';
import 'editor_components.dart';
import '../../../../core/utils/number_formatters.dart';
import 'utils/transaction_types.dart';

class TransactionEditorPage extends StatefulWidget {
  // Вместо просто Transaction принимаем DTO
  final TransactionWithItems? transactionWithItems;

  const TransactionEditorPage({super.key, this.transactionWithItems});

  @override
  State<TransactionEditorPage> createState() => _TransactionEditorPageState();
}

class _TransactionEditorPageState extends State<TransactionEditorPage> {
  // --- ДОБАВИТЬ ЭТИ ПЕРЕМЕННЫЕ ---
  TransactionType _type = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();

  String? _fromAccountId;
  String? _toAccountId;
  String? _categoryId;
  String? _activeTagForBatching;

  final List<TransactionItemDto> _items = [];

  final _amountCtrl = TextEditingController();
  final _storeCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _recipientCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Если это редактирование - заполняем поля
    if (widget.transactionWithItems != null) {
      final data = widget.transactionWithItems!;
      final t = data.transaction;

      // 1. Конвертируем тип из строки БД в Enum
      _type = TransactionType.values.firstWhere(
        (e) => e.dbValue == t.type,
        orElse: () => TransactionType.expense,
      );

      _selectedDate = t.date;

      // 2. Сумма (копейки -> рубли)
      _amountCtrl.text = (t.amount.toDouble() / 100)
          .toCurrencyString(); // Используем наш extension

      // 3. ID связей
      _fromAccountId = t.sourceAccountId;
      _toAccountId = t.targetAccountId;
      _categoryId = t.categoryId;

      // 4. Текстовые поля
      if (_type == TransactionType.transferPerson) {
        _recipientCtrl.text = t.shopName ?? "";
      } else {
        _storeCtrl.text = t.shopName ?? "";
      }
      _noteCtrl.text = t.note ?? "";

      // 5. Товары (самое важное!)
      // Конвертируем TransactionItem (Drift) -> TransactionItemDto (UI)
      // В DTO мы храним цену в рублях!
      _items.addAll(
        data.items.map(
          (i) => TransactionItemDto(
            name: i.name,
            price: i.price.toDouble() / 100, // Конвертация
            quantity: i.quantity,
            categoryId: i.categoryId,
            tags: [], // Теги пока пустые, так как мы их не храним в items
          ),
        ),
      );
    } else {
      // Если это создание новой - запускаем автовыбор счета
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _initDefaultAccount(),
      );
    }
  }

  void _initDefaultAccount() {
    final wallet = context.read<WalletProvider>();
    // Используем _fromAccountId
    if (wallet.accounts.isNotEmpty && _fromAccountId == null) {
      final main = wallet.accounts.firstWhere(
        (a) => a.isMain,
        orElse: () => wallet.accounts.first,
      );
      if (mounted) {
        setState(() => _fromAccountId = main.id); // Используем _fromAccountId
      }
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _storeCtrl.dispose();
    _noteCtrl.dispose();
    _recipientCtrl.dispose();
    super.dispose();
  }

  // --- ДОБАВИТЬ МЕТОД ПЕРЕСЧЕТА СУММЫ ---
  void _recalculateTotal() {
    if (_items.isEmpty) return;

    final total = _items.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    _amountCtrl.text = total.toCurrencyString(); // Используем Extension
  }

  // --- ДОБАВИТЬ МЕТОД ДОБАВЛЕНИЯ ТОВАРА ---
  void _addItem() async {
    // Диалог теперь возвращает DTO
    final newItem = await showDialog<TransactionItemDto>(
      context: context,
      builder: (_) => const AddItemDialog(),
    );

    if (newItem != null) {
      setState(() {
        _items.add(newItem);
        _recalculateTotal();
      });
    }
  }

  // МЕТОД СОХРАНЕНИЯ (ЗАГОТОВКА)
  Future<void> _saveTransaction() async {
    // 1. Валидация
    if (_amountCtrl.text.isEmpty) {
      _showSnack("Введите сумму", isError: true);
      return;
    }
    if (_fromAccountId == null) {
      _showSnack("Выберите счет", isError: true);
      return;
    }

    // 2. Подготовка данных
    HapticFeedback.mediumImpact();
    final amount =
        double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0.0;

    // Определяем имя магазина/получателя
    String? storeName = _storeCtrl.text.isNotEmpty ? _storeCtrl.text : null;
    if (_type == TransactionType.transferPerson &&
        _recipientCtrl.text.isNotEmpty) {
      storeName = _recipientCtrl.text;
    }

    // 3. Сохранение
    await context.read<WalletProvider>().addTransaction(
      id: widget.transactionWithItems?.transaction.id,
      amount: amount,
      type: _type.dbValue,
      accountId: _fromAccountId!,
      toAccountId: _toAccountId,
      categoryId: _categoryId,
      date: _selectedDate,
      storeName: storeName,
      note: _noteCtrl.text.isNotEmpty ? _noteCtrl.text : null,
      items: _items,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PulsePage(
      title: "Операция",
      subtitle: _type.subtitle, // Из Enum
      accentColor: _type.color, // Из Enum
      showBackButton: true,
      actions: [
        GlassCircleButton(
          icon: Icons.qr_code_scanner,
          onTap: () => HapticFeedback.mediumImpact(),
        ),
      ],
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildTypeSelector(),
          const SizedBox(height: 30),
          _buildAmountInput(),
          const SizedBox(height: 30),
          _buildMainProperties(),
          const SizedBox(height: 20),
          _buildDetailsInputs(),
          const SizedBox(height: 30),
          _buildItemsSection(),
          const SizedBox(height: 30),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    // В компонентах нужно обновить селектор, чтобы принимал Enum,
    // или пока мапим вручную для совместимости
    return TransactionTypeSelector(
      currentType: _type.dbValue,
      onTypeChanged: (val) {
        // Конвертируем строку обратно в Enum
        final newType = TransactionType.values.firstWhere(
          (e) => e.dbValue == val,
        );
        setState(() => _type = newType);
      },
    );
  }

  Widget _buildAmountInput() {
    return PulseLargeNumberInput(controller: _amountCtrl, color: _type.color);
  }

  Widget _buildMainProperties() {
    return Column(
      children: [
        // Дата
        EditorGlassTile(
          label: "ДАТА И ВРЕМЯ",
          value: DateFormat('d MMMM, HH:mm', 'ru').format(_selectedDate),
          icon: Icons.calendar_today,
          color: PulseColors.blue,
          onTap: () async {
            final picked = await PulsePickers.pickDateTime(
              context,
              initialDate: _selectedDate,
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
        ),
        const SizedBox(height: 10),

        // Счета
        AccountPickerSection(
          type: _type.dbValue,
          selectedFromId: _fromAccountId,
          selectedToId: _toAccountId,
          onFromChanged: (id) => setState(() => _fromAccountId = id),
          onToChanged: (id) => setState(() => _toAccountId = id),
        ),

        // Категория (если не перевод)
        if (_type != TransactionType.transfer) ...[
          const SizedBox(height: 10),
          CategoryPickerSection(
            selectedCategoryId: _categoryId,
            onCategoryChanged: (id) => setState(() => _categoryId = id),
          ),

          // Теги (вынесены в отдельный метод для чистоты)
          if (_categoryId != null) _buildTagsRow(),
        ],
      ],
    );
  }

  Widget _buildTagsRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _buildTagsList(context), // Твой старый метод, можно оставить
    );
  }

  Widget _buildDetailsInputs() {
    return Column(
      children: [
        if (_type == TransactionType.transferPerson)
          EditorInput(
            hint: "Кому (Имя)",
            icon: Icons.person_outline,
            controller: _recipientCtrl,
          )
        else if (_type != TransactionType.transfer)
          EditorInput(
            hint: "Магазин",
            icon: Icons.storefront,
            controller: _storeCtrl,
          ),

        const SizedBox(height: 10),
        EditorInput(hint: "Заметка", icon: Icons.notes, controller: _noteCtrl),
      ],
    );
  }

  Widget _buildTagsList(BuildContext context) {
    final provider = context.read<WalletProvider>();
    // Ищем теги для выбранной категории
    final categoryData = provider.categories.firstWhere(
      (c) => c.category.id == _categoryId,
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

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saveTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: _type.color,
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
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? PulseColors.red : PulseColors.green,
      ),
    );
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
