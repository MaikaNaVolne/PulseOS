import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../core/database/app_database.dart';
import '../../../../core/di/service_locator.dart';
import '../data/wallet_repository.dart';

class WalletProvider extends ChangeNotifier {
  late final WalletRepository _repo;

  // Храним подписку на базу, чтобы закрыть её, если провайдер удалится
  StreamSubscription? _accountsSubscription;

  // --- СОСТОЯНИЕ (То, что видит UI) ---
  List<Account> accounts = [];
  BigInt totalBalance = BigInt.zero;
  bool isLoading = true;

  WalletProvider() {
    _repo = WalletRepository(sl<AppDatabase>());
    _init();
  }

  // Кэш категорий для выбора
  List<CategoryWithTags> categories = [];

  StreamSubscription? _categoriesSubscription;

  void _init() {
    // Счета
    _accountsSubscription = _repo.watchAllAccounts().listen((data) {
      accounts = data;
      _calculateTotal();
      isLoading = false;
      notifyListeners();
    });

    // Категории + Теги
    _categoriesSubscription = _repo.watchAllCategories().listen((cats) async {
      final List<CategoryWithTags> list = [];
      for (var c in cats) {
        final tags = await _repo.getTagsForCategory(c.id);
        list.add(CategoryWithTags(c, tags.map((t) => t.name).toList()));
      }
      categories = list;
      notifyListeners();
    });
  }

  Future<void> saveCategory({
    required String? id,
    required String name,
    required String colorHex,
    required String iconKey,
    required List<String> tags,
  }) async {
    final catId = id ?? const Uuid().v4();

    final category = CategoriesCompanion(
      id: drift.Value(catId),
      name: drift.Value(name),
      colorHex: drift.Value(colorHex),
      iconKey: drift.Value(iconKey),
      moduleType: const drift.Value('finance'),
    );

    if (id == null) {
      await _repo.createCategory(category);
    } else {
      final cat = Category(
        id: catId,
        name: name,
        colorHex: colorHex,
        iconKey: iconKey,
        moduleType: 'finance',
        parentId: null,
      );
      await _repo.updateCategory(cat);
    }

    // Сохраняем теги
    if (tags.isNotEmpty) {
      await _repo.updateTags(catId, tags);
    }
  }

  // Метод для загрузки тегов при открытии диалога
  Future<List<String>> getTags(String categoryId) async {
    final tags = await _repo.getTagsForCategory(categoryId);
    return tags.map((t) => t.name).toList();
  }

  Future<void> deleteCategory(String id) async {
    await _repo.deleteCategory(id);
  }

  // МЕТОД СОЗДАНИЯ ТРАНЗАКЦИИ
  Future<void> addTransaction({
    required double amount,
    required String type, // 'expense', 'income', 'transfer'
    required String accountId,
    String? toAccountId,
    String? categoryId,
    DateTime? date,
    String? note,
    String? storeName,
    List<TransactionItemDto> items = const [], // DTO для позиций
  }) async {
    final transId = const Uuid().v4();
    final dateFinal = date ?? DateTime.now();

    // Конвертируем рубли в копейки
    final amountCents = BigInt.from((amount * 100).round());

    final transaction = TransactionsCompanion.insert(
      id: transId,
      type: type,
      sourceAccountId: accountId,
      targetAccountId: drift.Value(toAccountId),
      categoryId: drift.Value(categoryId),
      amount: amountCents,
      date: dateFinal,
      note: drift.Value(note),
      shopName: drift.Value(storeName),
    );

    final itemCompanions = items.map((i) {
      return TransactionItemsCompanion.insert(
        id: const Uuid().v4(),
        transactionId: transId,
        name: i.name,
        price: BigInt.from((i.price * 100).round()),
        quantity: drift.Value(i.quantity),
        categoryId: drift.Value(i.categoryId),
      );
    }).toList();

    await _repo.createTransaction(
      transaction: transaction,
      items: itemCompanions,
    );
  }

  void _calculateTotal() {
    BigInt sum = BigInt.zero;
    for (var acc in accounts) {
      if (!acc.isExcluded) {
        sum += acc.balance;
      }
    }
    totalBalance = sum;
  }

  // --- МЕТОДЫ ДЛЯ ВЫЗОВА ИЗ UI ---

  // Добавление
  Future<void> addAccount({
    required String name,
    required BigInt balance,
    required String colorHex,
    String? lastFourDigits,
    bool isMain = false,
    bool isExcluded = false,
  }) async {
    final newAccount = AccountsCompanion.insert(
      id: const Uuid().v4(),
      name: name,
      type: 'card', // Можно расширить позже
      currencyCode: 'RUB',
      balance: drift.Value(balance),
      colorHex: drift.Value(colorHex),
      cardNumber4: drift.Value(lastFourDigits),
      isMain: drift.Value(isMain),
      isExcluded: drift.Value(isExcluded),
    );

    await _repo.createAccount(newAccount);
  }

  // Редактирование
  Future<void> updateAccount(Account updatedAccount) async {
    await _repo.updateAccount(updatedAccount);
  }

  // Удаление
  Future<void> deleteAccount(String id) async {
    await _repo.deleteAccount(id);
  }

  @override
  void dispose() {
    _accountsSubscription?.cancel();
    _categoriesSubscription?.cancel(); // Не забудь закрыть
    super.dispose();
  }
}

class TransactionItemDto {
  final String name;
  final double price;
  final double quantity;
  final String? categoryId;

  TransactionItemDto({
    required this.name,
    required this.price,
    this.quantity = 1.0,
    this.categoryId,
  });
}

class CategoryWithTags {
  final Category category;
  final List<String> tags;
  CategoryWithTags(this.category, this.tags);
}
