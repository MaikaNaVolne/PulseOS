import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/pulse_theme.dart';
import '../../../domain/models/transaction_filter.dart';
import '../../../presentation/wallet_provider.dart';
import '../../transactions/utils/transaction_types.dart';

class FilterSheet extends StatelessWidget {
  const FilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();
    final filter = provider.currentFilter;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: PulseColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            _buildHeader(context, provider),
            const SizedBox(height: 24),

            // 1. Периоды
            _buildSectionTitle("ПЕРИОД"),
            const SizedBox(height: 12),
            _buildDatePresets(context, provider, filter),
            const SizedBox(height: 24),

            // 2. Тип операции
            _buildSectionTitle("ТИП ОПЕРАЦИИ"),
            const SizedBox(height: 12),
            _buildTypeSelector(provider, filter),
            const SizedBox(height: 24),

            // 3. Счета
            _buildSectionTitle("СЧЕТ"),
            const SizedBox(height: 12),
            _buildAccountSelector(provider, filter),
            const SizedBox(height: 24),

            // 4. Категории
            _buildSectionTitle("КАТЕГОРИИ"),
            const SizedBox(height: 12),
            _buildCategorySelector(provider, filter),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WalletProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Фильтры",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (provider.currentFilter.isActive)
          TextButton(
            onPressed: () => provider.updateFilter(TransactionFilter.empty()),
            child: const Text(
              "Сбросить",
              style: TextStyle(color: PulseColors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildDatePresets(
    BuildContext context,
    WalletProvider provider,
    TransactionFilter filter,
  ) {
    String dateLabel = "Выбрать период";
    if (filter.startDate != null && filter.endDate != null) {
      final fmt = DateFormat('d MMM', 'ru');
      dateLabel =
          "${fmt.format(filter.startDate!)} — ${fmt.format(filter.endDate!)}";
    }

    return GestureDetector(
      onTap: () async {
        final DateTimeRange? picked = await showDateRangePicker(
          context: context,
          initialDateRange: filter.startDate != null
              ? DateTimeRange(start: filter.startDate!, end: filter.endDate!)
              : null,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) => _calendarTheme(child!),
        );

        if (picked != null) {
          provider.updateFilter(
            filter.copyWith(
              startDate: picked.start,
              endDate: picked.end.add(const Duration(hours: 23, minutes: 59)),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: filter.startDate != null
                ? PulseColors.primary
                : Colors.white10,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dateLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(
              Icons.calendar_month,
              color: PulseColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Тема для календаря (в стиле Pulse)
  Widget _calendarTheme(Widget child) {
    return Theme(
      data: PulseTheme.darkTheme.copyWith(
        colorScheme: const ColorScheme.dark(
          primary: PulseColors.primary,
          onPrimary: Colors.black,
          surface: PulseColors.cardColor,
          onSurface: Colors.white,
        ),
      ),
      child: child,
    );
  }

  Widget _buildTypeSelector(WalletProvider provider, TransactionFilter filter) {
    return Wrap(
      spacing: 8,
      children: TransactionType.values
          .map(
            (t) => _FilterChip(
              label: t.label,
              isSelected: filter.type == t,
              onTap: () => provider.updateFilter(filter.copyWith(type: t)),
            ),
          )
          .toList(),
    );
  }

  Widget _buildAccountSelector(
    WalletProvider provider,
    TransactionFilter filter,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: provider.accounts
            .map(
              (acc) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _FilterChip(
                  label: acc.name,
                  isSelected: filter.accountId == acc.id,
                  onTap: () =>
                      provider.updateFilter(filter.copyWith(accountId: acc.id)),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCategorySelector(
    WalletProvider provider,
    TransactionFilter filter,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: provider.categories.map((catWithTags) {
        final cat = catWithTags.category;
        final isSelected = filter.categoryIds.contains(cat.id);
        return FilterChip(
          label: Text(cat.name),
          selected: isSelected,
          onSelected: (val) {
            final newList = List<String>.from(filter.categoryIds);
            val ? newList.add(cat.id) : newList.remove(cat.id);
            provider.updateFilter(filter.copyWith(categoryIds: newList));
          },
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }
}

// Вспомогательный виджет для чипсов в стиле Pulse
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? PulseColors.primary.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? PulseColors.primary : Colors.white10,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
