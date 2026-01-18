import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulseos/features/wallet/presentation/wallet_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/ui_kit/pulse_page.dart';
import '../../../../core/ui_kit/pulse_buttons.dart';
import '../../../../core/theme/pulse_theme.dart';

import 'widgets/category_card.dart';
import 'dialogs/category_dialog.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final categories = wallet.categories;

    return PulsePage(
      title: "Категории",
      subtitle: "НАСТРОЙКИ",
      accentColor: PulseColors.yellow,
      showBackButton: true,

      // Кнопка добавления в хедере (стеклянная)
      actions: [
        GlassCircleButton(icon: Icons.add, onTap: () => _showDialog(context)),
      ],

      body: categories.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text(
                  "Нет категорий",
                  style: TextStyle(color: Colors.white24),
                ),
              ),
            )
          : Column(
              children: categories.map((item) {
                return CategoryCard(
                  category: item.category,
                  onTap: () => _showDialog(context, category: item.category),
                );
              }).toList(),
            ),
    );
  }

  void _showDialog(BuildContext context, {Category? category}) {
    showDialog(
      context: context,
      builder: (_) => CategoryDialog(category: category),
    );
  }
}
