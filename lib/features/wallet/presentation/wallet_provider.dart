import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../core/database/app_database.dart';
import '../../../../core/di/service_locator.dart';
import '../data/tables/wallet_tables.dart';
import '../data/wallet_repository.dart';
import '../domain/models/transaction_filter.dart';

class WalletProvider extends ChangeNotifier {
  late final WalletRepository _repo;
  StreamSubscription? _accountsSubscription;
  StreamSubscription? _categoriesSubscription;
  StreamSubscription? _transactionsSubscription;

  List<Account> accounts = [];
  BigInt totalBalance = BigInt.zero;
  bool isLoading = true;
  List<CategoryWithTags> categories = [];
  List<TransactionWithItems> transactions = [];
  TransactionFilter _currentFilter = TransactionFilter.empty();

  WalletProvider() {
    _repo = WalletRepository(sl<AppDatabase>());
    _init();
  }

  TransactionFilter get currentFilter => _currentFilter;

  void _init() {
    _accountsSubscription = _repo.watchAllAccounts().listen((data) {
      accounts = data;
      _calculateTotal();
      isLoading = false;
      notifyListeners();
    });

    _initTransactionsStream();

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

  void _initTransactionsStream() {
    _transactionsSubscription?.cancel();
    _transactionsSubscription = _repo
        .watchTransactionsWithItems(filter: _currentFilter)
        .listen((data) {
          transactions = data;
          notifyListeners();
        });
  }

  void updateFilter(TransactionFilter newFilter) {
    _currentFilter = newFilter;
    _initTransactionsStream();
    notifyListeners();
  }

  // --- СЧЕТА ---
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
      type: 'card',
      currencyCode: 'RUB',
      balance: drift.Value(balance),
      colorHex: drift.Value(colorHex),
      cardNumber4: drift.Value(lastFourDigits),
      isMain: drift.Value(isMain),
      isExcluded: drift.Value(isExcluded),
    );
    await _repo.createAccount(newAccount);
  }

  Future<void> updateAccount(Account updatedAccount) async =>
      await _repo.updateAccount(updatedAccount);
  Future<void> deleteAccount(String id) async => await _repo.deleteAccount(id);

  // --- КАТЕГОРИИ ---
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
    );
    if (id == null)
      await _repo.createCategory(category);
    else
      await _repo.updateCategory(
        Category(
          id: catId,
          name: name,
          colorHex: colorHex,
          iconKey: iconKey,
          moduleType: 'finance',
          parentId: null,
        ),
      );
    await _repo.updateTags(catId, tags);
  }

  Future<List<String>> getTags(String categoryId) async {
    final tags = await _repo.getTagsForCategory(categoryId);
    return tags.map((t) => t.name).toList();
  }

  Future<void> deleteCategory(String id) async =>
      await _repo.deleteCategory(id);

  // --- ТРАНЗАКЦИИ (С ПЕРЕСЧЕТОМ) ---
  Future<void> addTransaction({
    String? id,
    required double amount,
    required String type,
    required String accountId,
    String? toAccountId,
    String? categoryId,
    DateTime? date,
    String? note,
    String? storeName,
    List<TransactionItemDto> items = const [],
  }) async {
    final transId = id ?? const Uuid().v4();
    final amountCents = BigInt.from((amount * 100).round());

    // 1. Откат старого баланса при редактировании
    if (id != null) {
      try {
        final oldData = transactions.firstWhere((t) => t.transaction.id == id);
        final oldT = oldData.transaction;
        final oldAcc = accounts.firstWhere((a) => a.id == oldT.sourceAccountId);

        BigInt revertedBalance = oldAcc.balance;
        if (oldT.type == 'expense' ||
            oldT.type == 'transfer' ||
            oldT.type == 'transfer_person') {
          revertedBalance += oldT.amount;
        } else {
          revertedBalance -= oldT.amount;
        }
        await _repo.updateAccount(oldAcc.copyWith(balance: revertedBalance));

        if (oldT.type == 'transfer' && oldT.targetAccountId != null) {
          final oldTarget = accounts.firstWhere(
            (a) => a.id == oldT.targetAccountId,
          );
          await _repo.updateAccount(
            oldTarget.copyWith(balance: oldTarget.balance - oldT.amount),
          );
        }
      } catch (e) {
        debugPrint("Balance revert failed: $e");
      }
    }

    // 2. Применяем новый баланс
    final fromAcc = accounts.firstWhere((a) => a.id == accountId);
    if (type == 'expense' || type == 'transfer' || type == 'transfer_person') {
      await _repo.updateAccount(
        fromAcc.copyWith(balance: fromAcc.balance - amountCents),
      );
    } else {
      await _repo.updateAccount(
        fromAcc.copyWith(balance: fromAcc.balance + amountCents),
      );
    }

    if (type == 'transfer' && toAccountId != null) {
      final toAcc = accounts.firstWhere((a) => a.id == toAccountId);
      await _repo.updateAccount(
        toAcc.copyWith(balance: toAcc.balance + amountCents),
      );
    }

    // 3. Сохраняем в БД
    await _repo.createTransaction(
      transaction: TransactionsCompanion.insert(
        id: transId,
        type: type,
        sourceAccountId: accountId,
        targetAccountId: drift.Value(toAccountId),
        categoryId: drift.Value(categoryId),
        amount: amountCents,
        date: date ?? DateTime.now(),
        note: drift.Value(note),
        shopName: drift.Value(storeName),
      ),
      items: items
          .map(
            (i) => TransactionItemsCompanion.insert(
              id: const Uuid().v4(),
              transactionId: transId,
              name: i.name,
              price: BigInt.from((i.price * 100).round()),
              quantity: drift.Value(i.quantity),
              categoryId: drift.Value(i.categoryId),
            ),
          )
          .toList(),
    );
  }

  void _calculateTotal() {
    totalBalance = accounts
        .where((a) => !a.isExcluded)
        .fold(BigInt.zero, (sum, a) => sum + a.balance);
  }

  @override
  void dispose() {
    _accountsSubscription?.cancel();
    _categoriesSubscription?.cancel();
    _transactionsSubscription?.cancel();
    super.dispose();
  }
}

class TransactionItemDto {
  String name;
  double price;
  double quantity;
  String? categoryId;
  List<String> tags;
  TransactionItemDto({
    required this.name,
    required this.price,
    this.quantity = 1.0,
    this.categoryId,
    this.tags = const [],
  });
}

class CategoryWithTags {
  final Category category;
  final List<String> tags;
  CategoryWithTags(this.category, this.tags);
}
