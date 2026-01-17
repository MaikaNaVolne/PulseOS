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

  void _init() {
    // Начинаем слушать стрим из репозитория
    _accountsSubscription = _repo.watchAllAccounts().listen((data) {
      accounts = data;
      _calculateTotal();
      isLoading = false;
      notifyListeners();
    });
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
    super.dispose();
  }
}
