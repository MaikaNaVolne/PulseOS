import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/transaction_filter.dart';
import '../../../presentation/wallet_provider.dart';
import '../../transactions/utils/transaction_types.dart';

class FilterSheet extends StatelessWidget {
  const FilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();
    final filter = provider.currentFilter;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: const BoxDecoration(
        color: Color(0xFF1E202C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Фильтры",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Тип операции (Чипсы)
            const Text(
              "ТИП ОПЕРАЦИИ",
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: TransactionType.values.map((type) {
                final isSelected = filter.type == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(type.label),
                    selected: isSelected,
                    onSelected: (val) {
                      provider.updateFilter(
                        filter.copyWith(type: val ? type : null),
                      );
                    },
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Сброс
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  provider.updateFilter(TransactionFilter.empty());
                  Navigator.pop(context);
                },
                child: const Text(
                  "Сбросить всё",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
