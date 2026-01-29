import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Core
import '../../../../core/database/app_database.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/ui_kit/pulse_page.dart';
import '../../../../core/ui_kit/pulse_buttons.dart';
import '../../../../core/ui_kit/pulse_large_number_input.dart';
import '../../../../core/ui_kit/pulse_pickers.dart';
import '../../../../core/theme/pulse_theme.dart';
import '../../../../core/utils/number_formatters.dart';

// Features
import '../../../settings/ui/widgets/api_key_dialog.dart';
import '../../data/receipt_service.dart';
import '../../data/tables/wallet_tables.dart';
import '../../presentation/wallet_provider.dart';
import '../scan/qr_scan_page.dart';
import 'dialog/add_item_dialog.dart';
import 'utils/transaction_types.dart';
import 'editor_components.dart';
import '../split/split_selection_page.dart';

class TransactionEditorPage extends StatefulWidget {
  final TransactionWithItems? transactionWithItems;

  const TransactionEditorPage({super.key, this.transactionWithItems});

  @override
  State<TransactionEditorPage> createState() => _TransactionEditorPageState();
}

class _TransactionEditorPageState extends State<TransactionEditorPage> {
  // --- ПОЛЯ СОСТОЯНИЯ ---
  TransactionType _type = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();

  String? _fromAccountId;
  String? _toAccountId;
  String? _categoryId;

  String _p2pDirection = 'out';
  bool _isScanning = false;

  String? _activeTagForBatching;
  int? _selectedItemIndex;

  final List<TransactionItemDto> _items = [];

  final _amountCtrl = TextEditingController();
  final _storeCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _recipientCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.transactionWithItems != null) {
      final data = widget.transactionWithItems!;
      final t = data.transaction;

      _type = TransactionType.values.firstWhere(
        (e) => e.dbValue == t.type,
        orElse: () => TransactionType.expense,
      );

      if (t.type == 'transfer_person_incoming') {
        _type = TransactionType.transferPerson;
        _p2pDirection = 'in';
      }

      _selectedDate = t.date;
      _amountCtrl.text = (t.amount.toDouble() / 100).toCurrencyString();
      _fromAccountId = t.sourceAccountId;
      _toAccountId = t.targetAccountId;
      _categoryId = t.categoryId;

      if (_type == TransactionType.transferPerson) {
        _recipientCtrl.text = t.shopName ?? "";
      } else {
        _storeCtrl.text = t.shopName ?? "";
      }
      _noteCtrl.text = t.note ?? "";

      _items.addAll(
        data.items.map(
          (i) => TransactionItemDto(
            name: i.name,
            price: i.price.toDouble() / 100,
            quantity: i.quantity,
            categoryId: i.categoryId,
            tags: [],
          ),
        ),
      );
    } else {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _initDefaultAccount(),
      );
    }
  }

  void _initDefaultAccount() {
    final wallet = context.read<WalletProvider>();
    if (wallet.accounts.isNotEmpty && _fromAccountId == null) {
      final main = wallet.accounts.firstWhere(
        (a) => a.isMain,
        orElse: () => wallet.accounts.first,
      );
      if (mounted) setState(() => _fromAccountId = main.id);
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

  // --- ЛОГИКА ---

  void _recalculateTotal() {
    if (_items.isEmpty) return;
    final total = _items.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    _amountCtrl.text = total.toCurrencyString();
  }

  Future<void> _addItem() async {
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

  Future<void> _handleScan() async {
    HapticFeedback.mediumImpact();
    final settings = sl<SettingsService>();

    if (!settings.hasToken) {
      final result = await showDialog(
        context: context,
        builder: (_) => const ApiKeyDialog(),
      );
      if (result != true) return;
    }

    if (!mounted) return;

    String? qrCode;
    if (Platform.isAndroid || Platform.isIOS) {
      qrCode = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QrScanPage()),
      );
    } else {
      qrCode = await _showManualQrDialog();
    }

    if (qrCode != null && mounted) _loadReceipt(qrCode);
  }

  Future<String?> _showManualQrDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E202C),
        title: const Text(
          "Ввод данных чека",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "t=...&s=..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Отмена"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text("ОК"),
          ),
        ],
      ),
    );
  }

  Future<void> _loadReceipt(String qrRaw) async {
    setState(() => _isScanning = true);
    try {
      final token = sl<SettingsService>().receiptToken!;
      final data = await ReceiptService.getReceipt(qrRaw: qrRaw, token: token);

      if (mounted) {
        setState(() {
          _selectedDate = data.date;
          if (data.shopName != null) _storeCtrl.text = data.shopName!;
          _items.addAll(data.items);
          _recalculateTotal();
          _isScanning = false;
        });
        _showSnack("Чек загружен");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        _showSnack("Ошибка: $e", isError: true);
      }
    }
  }

  Future<void> _saveTransaction() async {
    if (_amountCtrl.text.isEmpty) {
      _showSnack("Введите сумму", isError: true);
      return;
    }
    if (_fromAccountId == null) {
      _showSnack("Выберите счет", isError: true);
      return;
    }

    HapticFeedback.mediumImpact();
    final amount =
        double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0.0;

    String? storeName = _storeCtrl.text.isNotEmpty ? _storeCtrl.text : null;
    String dbType = _type.dbValue;

    if (_type == TransactionType.transferPerson) {
      storeName = _recipientCtrl.text;
      if (_p2pDirection == 'in') dbType = 'transfer_person_incoming';
    }

    await context.read<WalletProvider>().addTransaction(
      id: widget.transactionWithItems?.transaction.id,
      amount: amount,
      type: dbType,
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

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? PulseColors.red : PulseColors.green,
      ),
    );
  }

  void _editItem(int index) async {
    final item = _items[index];
    final edited = await showDialog<TransactionItemDto>(
      context: context,
      builder: (_) => AddItemDialog(item: item),
    );
    if (edited != null) {
      setState(() {
        _items[index] = edited;
        _recalculateTotal();
      });
    }
  }

  // ===========================================================================
  // ОСНОВНОЙ BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final themeColor = _type.color;

    return PulsePage(
      title: "Операция",
      subtitle: _type.subtitle,
      accentColor: themeColor,
      showBackButton: true,
      // ВАЖНО: Отключаем встроенный скролл, чтобы Stack работал правильно
      useScroll: false,
      actions: [
        GlassCircleButton(icon: Icons.qr_code_scanner, onTap: _handleScan),
      ],
      body: Stack(
        children: [
          // 1. Списочная часть (скроллится)
          ListView(
            padding: const EdgeInsets.only(bottom: 120), // Место под кнопку
            physics: const BouncingScrollPhysics(),
            children: [
              const SizedBox(height: 10),

              TransactionTypeSelector(
                currentType: _type.dbValue,
                onTypeChanged: (val) {
                  final newType = TransactionType.values.firstWhere(
                    (e) => e.dbValue == val,
                    orElse: () => TransactionType.expense,
                  );
                  setState(() => _type = newType);
                },
              ),

              if (_type == TransactionType.transferPerson) ...[
                const SizedBox(height: 12),
                _buildP2PDirectionToggle(),
              ],

              const SizedBox(height: 24),

              PulseLargeNumberInput(controller: _amountCtrl, color: themeColor),

              const SizedBox(height: 32),

              EditorGlassTile(
                label: "ДАТА",
                value: DateFormat('d MMM, HH:mm', 'ru').format(_selectedDate),
                icon: Icons.calendar_today,
                color: PulseColors.blue,
                onTap: () async {
                  final d = await PulsePickers.pickDateTime(
                    context,
                    initialDate: _selectedDate,
                  );
                  if (d != null) setState(() => _selectedDate = d);
                },
              ),
              const SizedBox(height: 10),

              AccountPickerSection(
                type: _type.dbValue,
                selectedFromId: _fromAccountId,
                selectedToId: _toAccountId,
                onFromChanged: (id) => setState(() => _fromAccountId = id),
                onToChanged: (id) => setState(() => _toAccountId = id),
              ),

              if (_type != TransactionType.transfer) ...[
                const SizedBox(height: 10),
                CategoryPickerSection(
                  selectedCategoryId: _categoryId,
                  onCategoryChanged: (id) => setState(() => _categoryId = id),
                ),
                if (_categoryId != null) _buildTagsList(wallet),
              ],

              const SizedBox(height: 20),

              if (_type == TransactionType.transferPerson)
                EditorInput(
                  hint: "Кому / От кого",
                  icon: Icons.person,
                  controller: _recipientCtrl,
                )
              else if (_type != TransactionType.transfer)
                EditorInput(
                  hint: "Магазин",
                  icon: Icons.storefront,
                  controller: _storeCtrl,
                ),

              const SizedBox(height: 10),
              EditorInput(
                hint: "Заметка",
                icon: Icons.notes,
                controller: _noteCtrl,
              ),

              const SizedBox(height: 32),

              if (_type != TransactionType.transfer) _buildItemsSection(),
            ],
          ),

          // 2. Кнопка сохранения (фиксирована внизу)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: SizedBox(
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
          ),

          // 3. Оверлей загрузки
          if (_isScanning)
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                child: const Center(
                  child: CircularProgressIndicator(color: PulseColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ ---

  Widget _buildP2PDirectionToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _toggleBtn(
            "Я отправил (-)",
            _p2pDirection == 'out',
            PulseColors.purple,
            () => setState(() => _p2pDirection = 'out'),
          ),
          _toggleBtn(
            "Мне прислали (+)",
            _p2pDirection == 'in',
            PulseColors.green,
            () => setState(() => _p2pDirection = 'in'),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(String text, bool active, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? color.withValues(alpha: 0.5) : Colors.transparent,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: active ? Colors.white : Colors.white38,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagsList(WalletProvider provider) {
    final catData = provider.categories.firstWhere(
      (c) => c.category.id == _categoryId,
      orElse: () => CategoryWithTags(
        const Category(id: '0', name: '', colorHex: '', moduleType: ''),
        [],
      ),
    );

    if (catData.tags.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: catData.tags.length,
        itemBuilder: (ctx, i) {
          final tag = catData.tags[i];
          final isActive = _activeTagForBatching == tag;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(tag),
              backgroundColor: isActive
                  ? PulseColors.primary.withValues(alpha: 0.2)
                  : Colors.white10,
              labelStyle: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
              ),
              onPressed: () {
                setState(() => _activeTagForBatching = isActive ? null : tag);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemsSection() {
    final bool hasItems = _items.isNotEmpty;
    return Column(
      children: [
        ItemsListHeader(
          hasItems: hasItems,
          onAdd: _addItem,
          onSplit: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SplitSelectionPage(
                  items: _items,
                  onSave: (list) {
                    setState(() {
                      _items.clear();
                      _items.addAll(list);
                      _recalculateTotal();
                    });
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        if (!hasItems)
          _buildEmptyPlaceholder()
        else
          Column(
            children: _items.asMap().entries.map((e) {
              return TransactionItemRow(
                index: e.key,
                item: e.value,
                isSelected: _selectedItemIndex == e.key,
                onTap: () {
                  if (_activeTagForBatching != null) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      if (e.value.tags.contains(_activeTagForBatching)) {
                        e.value.tags.remove(_activeTagForBatching);
                      } else {
                        e.value.tags.add(_activeTagForBatching!);
                      }
                    });
                  } else {
                    _editItem(e.key);
                  }
                },
                onDelete: () {
                  setState(() {
                    _items.removeAt(e.key);
                    _recalculateTotal();
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long, color: Colors.white10, size: 32),
          SizedBox(height: 8),
          Text("Список пуст", style: TextStyle(color: Colors.white24)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ЛОКАЛЬНЫЕ КОМПОНЕНТЫ (Чтобы не плодить файлы)
// -----------------------------------------------------------------------------

class ItemsListHeader extends StatelessWidget {
  final bool hasItems;
  final VoidCallback onAdd;
  final VoidCallback onSplit;
  const ItemsListHeader({
    super.key,
    required this.hasItems,
    required this.onAdd,
    required this.onSplit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "ПОЗИЦИИ ЧЕКА",
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        Row(
          children: [
            if (hasItems)
              GestureDetector(
                onTap: onSplit,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.call_split,
                    size: 16,
                    color: Colors.blue,
                  ),
                ),
              ),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: PulseColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  size: 18,
                  color: PulseColors.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class StoreAutocompleteInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSelected;
  const StoreAutocompleteInput({
    super.key,
    required this.controller,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return EditorInput(
      controller: controller,
      hint: "Магазин (Пятерочка, Ozon...)",
      icon: Icons.storefront,
    );
  }
}

class TransactionItemRow extends StatelessWidget {
  final int index;
  final TransactionItemDto item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TransactionItemRow({
    super.key,
    required this.index,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final total = item.price * item.quantity;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? PulseColors.primary.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: PulseColors.primary) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${item.quantity} x ${item.price.toStringAsFixed(2)} ₽",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${total.toStringAsFixed(2)} ₽",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: onDelete,
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
            if (item.tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
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
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
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
}
