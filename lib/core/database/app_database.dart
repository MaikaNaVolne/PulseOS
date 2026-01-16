import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../features/wallet/data/tables/wallet_tables.dart';

// Генерируемый файл.
part 'app_database.g.dart';

@DriftDatabase(
  tables: [Currencies, Categories, Accounts, Transactions, TransactionItems],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;
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
