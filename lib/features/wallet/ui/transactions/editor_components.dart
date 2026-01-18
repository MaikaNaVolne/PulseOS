import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/pulse_theme.dart';
import '../../../../core/utils/app_routes.dart';
import '../../presentation/wallet_provider.dart';
import '../../../../core/utils/icon_helper.dart';

// 1. ВЫБОР ТИПА (СЛАЙДЕР)
class TransactionTypeSelector extends StatelessWidget {
  final String
  currentType; // 'expense', 'income', 'transfer', 'transfer_person'
  final Function(String) onTypeChanged;

  const TransactionTypeSelector({
    super.key,
    required this.currentType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        // Чтобы влезло на узких экранах
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _TypeBtn("Расход", "expense", PulseColors.red),
            _TypeBtn("Доход", "income", PulseColors.green),
            _TypeBtn("Перевод", "transfer", PulseColors.blue),
            _TypeBtn("Людям", "transfer_person", PulseColors.purple),
          ],
        ),
      ),
    );
  }

  Widget _TypeBtn(String label, String value, Color color) {
    final isSelected = currentType == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTypeChanged(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white38,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// 2. СТЕКЛЯННАЯ ПЛИТКА ВЫБОРА (ДАТА, СЧЕТ, КАТЕГОРИЯ)
class EditorGlassTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const EditorGlassTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 3. ПОЛЕ ВВОДА (Магазин, Заметка)
class EditorInput extends StatelessWidget {
  final String hint;
  final IconData icon;
  final TextEditingController? controller;

  const EditorInput({
    super.key,
    required this.hint,
    required this.icon,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.white30, size: 20),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

// 3. СЕКЦИЯ ВЫБОРА СЧЕТОВ
class AccountPickerSection extends StatelessWidget {
  final String type; // 'expense', 'income', 'transfer'
  final String? selectedFromId;
  final String? selectedToId;
  final Function(String) onFromChanged;
  final Function(String) onToChanged;

  const AccountPickerSection({
    super.key,
    required this.type,
    required this.selectedFromId,
    this.selectedToId,
    required this.onFromChanged,
    required this.onToChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Получаем доступ к счетам через провайдер
    final provider = context.watch<WalletProvider>();
    final accounts = provider.accounts;

    // Ищем выбранный счет или берем первый (основной) по умолчанию
    final fromAccount = accounts.firstWhere(
      (a) => a.id == selectedFromId,
      orElse: () => accounts.isNotEmpty ? accounts.first : _emptyAccount(),
    );

    final toAccount = accounts.firstWhere(
      (a) => a.id == selectedToId,
      orElse: () => _emptyAccount(),
    );

    return Column(
      children: [
        // 1. ОТКУДА / КУДА (Основной счет)
        EditorGlassTile(
          label: type == 'income' ? "ЗАЧИСЛИТЬ НА" : "СПИСАТЬ С",
          value: fromAccount.name,
          icon: Icons.account_balance_wallet,
          color: _hexToColor(fromAccount.colorHex),
          onTap: () => _showAccountSheet(context, accounts, onFromChanged),
        ),

        // 2. ДЛЯ ПЕРЕВОДА (Второй счет)
        if (type == 'transfer') ...[
          const SizedBox(height: 10),
          EditorGlassTile(
            label: "ПЕРЕВЕСТИ НА",
            value: toAccount.id.isEmpty ? "Выбрать счет" : toAccount.name,
            icon: Icons.subdirectory_arrow_right,
            color: toAccount.id.isEmpty
                ? Colors.white30
                : _hexToColor(toAccount.colorHex),
            onTap: () => _showAccountSheet(context, accounts, onToChanged),
          ),
        ],
      ],
    );
  }

  // Заглушка, если счетов нет
  // Заглушка, если счетов нет (все поля теперь заполнены)
  Account _emptyAccount() => Account(
    id: '',
    name: 'Нет счетов',
    type: 'card',
    currencyCode: 'RUB',
    balance: BigInt.zero,
    creditLimit: BigInt.zero, // Добавили
    colorHex: '#808080',
    iconKey: 'wallet', // Добавили
    isMain: false, // Добавили
    isExcluded: false, // Добавили
    isArchived: false, // Добавили
  );

  // Конвертер цвета
  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.grey;
    }
  }

  // --- ЛОГИКА ДИАЛОГА (UI) ---
  void _showAccountSheet(
    BuildContext context,
    List<Account> accounts,
    Function(String) onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E202C), // Непрозрачный фон, чтобы текст читался
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Маркер для свайпа
                Container(
                  margin: const EdgeInsets.only(top: 10),
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
                    "Выберите счет",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: accounts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final acc = accounts[index];
                      final color = _hexToColor(acc.colorHex);
                      final balance = (acc.balance.toDouble() / 100)
                          .toStringAsFixed(0);

                      return GestureDetector(
                        onTap: () {
                          onSelect(acc.id);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Цветная точка (миниатюра)
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Название
                              Expanded(
                                child: Text(
                                  acc.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                              // Баланс
                              Text(
                                "$balance ₽",
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CategoryPickerSection extends StatelessWidget {
  final String? selectedCategoryId;
  final Function(String) onCategoryChanged;

  const CategoryPickerSection({
    super.key,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Ищем выбранную категорию в провайдере
    final provider = context.watch<WalletProvider>();
    // provider.categories теперь хранит CategoryWithTags

    Category? selectedCategory;
    try {
      selectedCategory = provider.categories
          .firstWhere((c) => c.category.id == selectedCategoryId)
          .category;
    } catch (_) {}

    final name = selectedCategory?.name ?? "Выбрать категорию";
    final icon = selectedCategory != null
        ? getIcon(selectedCategory.iconKey ?? 'category')
        : Icons.category;
    final color = selectedCategory != null
        ? _hexToColor(selectedCategory.colorHex)
        : PulseColors.yellow;

    return EditorGlassTile(
      label: "КАТЕГОРИЯ",
      value: name,
      icon: icon,
      color: color,
      onTap: () =>
          _showCategorySheet(context, provider.categories, onCategoryChanged),
    );
  }

  // Вспомогательный метод цвета
  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.grey;
    }
  }

  void _showCategorySheet(
    BuildContext context,
    List<CategoryWithTags> categories,
    Function(String) onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Чтобы можно было растянуть на пол-экрана
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
                  "Выберите категорию",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: categories.length + 1, // +1 для кнопки "Настроить"
                  itemBuilder: (ctx, index) {
                    if (index == categories.length) {
                      return _ManageButton(
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.pushNamed(context, AppRoutes.category);
                        },
                      );
                    }

                    final item = categories[index];
                    final cat = item.category;
                    final color = _hexToColor(cat.colorHex);

                    return GestureDetector(
                      onTap: () {
                        onSelect(cat.id);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              getIcon(cat.iconKey ?? 'category'),
                              color: color,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              cat.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
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
}

class _ManageButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ManageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings, color: Colors.white54, size: 24),
            SizedBox(height: 8),
            Text(
              "Настроить",
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
