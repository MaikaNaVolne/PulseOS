import 'package:drift/drift.dart';

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

// --- 3. СЧЕТА ---
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
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
