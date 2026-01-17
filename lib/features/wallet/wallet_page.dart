import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pulseos/features/wallet/presentation/wallet_provider.dart';
import 'package:pulseos/features/wallet/ui/dialogs/account_dialog.dart';
import '../../core/ui_kit/pulse_page.dart';
import '../../core/theme/pulse_theme.dart';
import 'ui/widgets/account_card.dart'; // Импортируем карточку

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PulsePage(
      title: "Кошелек",
      subtitle: "ФИНАНСЫ",
      accentColor: PulseColors.primary,

      // Список счетов
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Блок общего баланса
          const _TotalBalanceBlock(),

          const SizedBox(height: 32),

          // 2. Заголовок секции счетов
          _buildSectionHeader("МОИ СЧЕТА", Icons.add, () {
            showDialog(
              context: context,
              builder: (context) => const AccountDialog(),
            );
          }),

          const SizedBox(height: 16),

          // 3. Горизонтальная карусель карт
          SizedBox(
            height: 190,
            child: Consumer<WalletProvider>(
              builder: (context, provider, child) {
                if (provider.accounts.isEmpty) {
                  return const Center(
                    child: Text("Нет счетов. Добавьте первый!"),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: provider.accounts.length,
                  itemBuilder: (context, index) {
                    final account = provider.accounts[index];
                    // Конвертируем цвет из HEX строки
                    final color = _hexToColor(account.colorHex);

                    return AccountCard(
                      name: account.name,
                      balance: (account.balance / BigInt.from(100))
                          .toStringAsFixed(0),
                      cardNumber: account.cardNumber4,
                      accentColor: color,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AccountDialog(account: account),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          // 4. Инструменты (Долги, отчеты и т.д.)
          _buildSectionHeader("ИНСТРУМЕНТЫ", null, null),
          // Тут позже будет сетка инструментов
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData? actionIcon,
    VoidCallback? onAction,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        if (actionIcon != null)
          GestureDetector(
            onTap: onAction,
            child: Icon(actionIcon, color: PulseColors.primary, size: 20),
          ),
      ],
    );
  }

  // Вспомогательная функция (положи в utils)
  Color _hexToColor(String hex) {
    return Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000);
  }
}

class _TotalBalanceBlock extends StatelessWidget {
  const _TotalBalanceBlock();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();

    final double amout = provider.totalBalance.toDouble() / 100;
    final formatter = NumberFormat("#,##0.00", "ru_RU");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "ОБЩИЙ БАЛАНС",
          style: TextStyle(
            color: Colors.white38,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              formatter.format(amout),
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "₽",
              style: TextStyle(
                fontSize: 24,
                color: PulseColors.primary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Мини-тренд (проценты)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: PulseColors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            "+4.2% в этом месяце",
            style: TextStyle(
              color: PulseColors.teal,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
