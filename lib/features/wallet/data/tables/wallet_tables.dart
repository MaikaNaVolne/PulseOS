import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';

// --- 1. ВАЛЮТЫ ---
class Currencies extends Table {
  TextColumn get code => text().withLength(min: 3, max: 3)();
  TextColumn get name => text()(); // "Рубль"
  TextColumn get symbol => text().withLength(max: 5)(); // "₽"
  IntColumn get precision =>
      integer().withDefault(const Constant(2))(); // Кол-во знаков (копейки = 2)

  @override
  Set<Column> get primaryKey => {code};
}

// --- 2. КАТЕГОРИИ ---
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get iconKey => text().nullable()();
  TextColumn get colorHex => text().withLength(max: 7)();

  // Связь с родителем (для подкатегорий)
  TextColumn get parentId => text().nullable().references(Categories, #id)();

  // Тип модуля (чтобы отделить категории Еды от Финансов)
  TextColumn get moduleType => text().withDefault(const Constant('finance'))();

  @override
  Set<Column> get primaryKey => {id};
}

class Tags extends Table {
  TextColumn get id => text()();

  // Связь с категорией
  TextColumn get categoryId => text().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- 3. СЧЕТА ---
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get cardNumber4 => text().nullable().withLength(min: 4, max: 4)();
  TextColumn get currencyCode => text().references(Currencies, #code)();
  Int64Column get balance => int64().withDefault(Constant(BigInt.zero))();
  Int64Column get creditLimit => int64().withDefault(Constant(BigInt.zero))();
  TextColumn get colorHex => text().withDefault(const Constant('#2fa33d'))();
  TextColumn get iconKey => text().withDefault(const Constant('wallet'))();
  BoolColumn get isMain => boolean().withDefault(const Constant(false))();
  BoolColumn get isExcluded => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// --- 4. ТРАНЗАКЦИИ ---
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get sourceAccountId => text().references(Accounts, #id)();
  TextColumn get targetAccountId =>
      text().nullable().references(Accounts, #id)();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  Int64Column get amount => int64()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get shopName => text().nullable()();
  TextColumn get externalReceiptId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- 5. ПОЗИЦИИ ЧЕКА (ДЕТАЛИЗАЦИЯ) ---
class TransactionItems extends Table {
  TextColumn get id => text()();

  // Ссылка на транзакцию
  TextColumn get transactionId =>
      text().references(Transactions, #id, onDelete: KeyAction.cascade)();

  TextColumn get name => text()();
  Int64Column get price => int64()();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();

  // Товар может иметь СВОЮ категорию (для сплита)
  TextColumn get categoryId => text().nullable().references(Categories, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

class TransactionWithItems {
  final Transaction transaction;
  final List<TransactionItem> items;
  final Category? category;
  final Account? account;

  TransactionWithItems({
    required this.transaction,
    this.items = const [],
    this.category,
    this.account,
  });
}

// --- 6. ДОЛГИ ---
class Debts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()(); // Имя должника или кому должен
  Int64Column get amount => int64()(); // Сумма (в копейках)

  // Тип: true = "Мне должны", false = "Я должен"
  BoolColumn get isOweMe => boolean().withDefault(const Constant(true))();

  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()(); // Срок возврата

  // --- Настройки процентов ---
  // Тип процента: 'none', 'fixed', 'percent'
  TextColumn get interestType => text().withDefault(const Constant('none'))();
  // Период: 'day', 'week', 'month', 'year'
  TextColumn get interestPeriod => text().nullable()();
  RealColumn get interestRate => real().withDefault(const Constant(0.0))();

  // --- Настройки штрафов ---
  // Тип штрафа: 'none', 'fixed', 'percent'
  TextColumn get penaltyType => text().withDefault(const Constant('none'))();
  // Период штрафа
  TextColumn get penaltyPeriod => text().nullable()();
  RealColumn get penaltyRate => real().withDefault(const Constant(0.0))();

  // Статус
  BoolColumn get isClosed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get closedDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- 7. ПЛАНИРУЕМЫЕ ОПЕРАЦИИ ---
class PlannedTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  Int64Column get amount => int64()();
  TextColumn get type => text()(); // 'income', 'expense'
  DateTimeColumn get date => dateTime()();

  // Связи
  TextColumn get accountId => text().nullable().references(Accounts, #id)();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();

  // Статус
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  // Рекурсия (Повторы)
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  // 'daily', 'weekly', 'monthly', 'yearly'
  TextColumn get recurrenceType => text().nullable()();
  IntColumn get recurrenceInterval =>
      integer().nullable()(); // Раз в 2 недели и т.д.

  @override
  Set<Column> get primaryKey => {id};
}
