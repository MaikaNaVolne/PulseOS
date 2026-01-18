import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../features/wallet/data/tables/wallet_tables.dart';

// Генерируемый файл.
part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Currencies,
    Categories,
    Tags,
    Accounts,
    Transactions,
    TransactionItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(NativeDatabase db) : super(db);
  @override
  int get schemaVersion => 2; // Убедись, что версия актуальна

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll(); // Создаем все таблицы
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.addColumn(accounts, accounts.cardNumber4);
        }
      },
      beforeOpen: (details) async {
        // 1. ВКЛЮЧАЕМ ПОДДЕРЖКУ ВНЕШНИХ КЛЮЧЕЙ (обязательно для SQLite)
        await customStatement('PRAGMA foreign_keys = ON');

        // 2. ДОБАВЛЯЕМ ДЕФОЛТНУЮ ВАЛЮТУ
        // insertOnConflictUpdate не даст создать дубликат, если RUB уже есть
        await into(currencies).insertOnConflictUpdate(
          CurrenciesCompanion.insert(
            code: 'RUB',
            name: 'Российский рубль',
            symbol: '₽',
          ),
        );
      },
    );
  }
}

// Функция для открытия соединения
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // 1. Находим папку для хранения (Documents/PulseOS)
    final dbFolder = await getApplicationDocumentsDirectory();

    // 2. Создаем файл db.sqlite
    final file = File(p.join(dbFolder.path, 'pulse_v2.sqlite'));

    return NativeDatabase.createInBackground(file);
  });
}
