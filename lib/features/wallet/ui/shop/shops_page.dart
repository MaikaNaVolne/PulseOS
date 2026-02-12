import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/pulse_theme.dart';
import '../../../../core/ui_kit/pulse_page.dart';
import '../../../../core/ui_kit/pulse_buttons.dart';
import '../../domain/models/shop_stats.dart';
import 'widgets/shop_tile.dart';

class ShopsPage extends StatefulWidget {
  const ShopsPage({super.key});

  @override
  State<ShopsPage> createState() => _ShopsPageState();
}

class _ShopsPageState extends State<ShopsPage> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PulsePage(
      title: "Магазины",
      subtitle: "МЕСТА ПОКУПОК",
      accentColor: PulseColors.blue,
      showBackButton: true,
      // Список кнопок в шапке
      actions: [
        GlassCircleButton(
          icon: Icons.search,
          onTap: () {
            // Фокус на поиск или просто скролл вверх
          },
        ),
      ],
      body: StreamBuilder<List<ShopStats>>(
        // Обращаемся напрямую к нашему новому DAO
        stream: sl<AppDatabase>().shopsDao.watchShops(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: PulseColors.blue),
            );
          }

          final allShops = snapshot.data ?? [];

          // Логика поиска
          final filteredShops = allShops.where((s) {
            return s.name.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          if (allShops.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Поле поиска (стеклянное)
              _buildSearchField(),

              const SizedBox(height: 24),

              // 2. Сводка (Топ магазинов)
              if (_searchQuery.isEmpty && allShops.length >= 2) ...[
                _buildTopStats(allShops),
                const SizedBox(height: 32),
              ],

              // 3. Заголовок списка
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  "ВСЕ МЕСТА",
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              // 4. Список магазинов
              ...filteredShops.map(
                (shop) => ShopTile(
                  shop: shop,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    // Переход на детали магазина (будет реализован на Шаге 4)
                    _navigateToShopDetail(context, shop.name);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: "Поиск по названию...",
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
              prefixIcon: const Icon(
                Icons.search,
                color: PulseColors.blue,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.white38,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = "");
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopStats(List<ShopStats> shops) {
    // Самый дорогой магазин
    final expensive = shops.reduce(
      (a, b) => a.totalSpent > b.totalSpent ? a : b,
    );
    // Самый частый
    final frequent = shops.first; // Т.к. в DAO уже есть сортировка по визитам

    return Row(
      children: [
        Expanded(
          child: _StatMiniCard(
            label: "ЛЮБИМЫЙ",
            title: frequent.name,
            icon: Icons.repeat_rounded,
            color: PulseColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatMiniCard(
            label: "ЗАТРАТНЫЙ",
            title: expensive.name,
            icon: Icons.payments_outlined,
            color: PulseColors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.storefront_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.05),
          ),
          const SizedBox(height: 16),
          const Text(
            "Магазины не найдены",
            style: TextStyle(color: Colors.white24),
          ),
        ],
      ),
    );
  }

  void _navigateToShopDetail(BuildContext context, String shopName) {
    // Реализуем на следующем шаге
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Переход к истории: $shopName")));
  }
}

class _StatMiniCard extends StatelessWidget {
  final String label, title;
  final IconData icon;
  final Color color;

  const _StatMiniCard({
    required this.label,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
