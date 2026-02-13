import 'package:drift/drift.dart';

// --- ТАБЛИЦА: СОН ---
class SleepEntries extends Table {
  TextColumn get id => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();

  IntColumn get quality => integer()();
  IntColumn get wakeEase => integer()();
  IntColumn get energyLevel => integer()();

  TextColumn get sleepType => text().withDefault(const Constant('night'))();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- ТАБЛИЦА: СПРАВОЧНИК ФАКТОРОВ ---
class SleepFactors extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get impactType => text().withDefault(const Constant('neutral'))();

  @override
  Set<Column> get primaryKey => {id};
}

// --- ТАБЛИЦА: СВЯЗЬ (МНОГИЕ-КО-МНОГИМ) ---
class SleepFactorLinks extends Table {
  TextColumn get id => text()();
  // Ссылка на сон
  TextColumn get sleepId =>
      text().references(SleepEntries, #id, onDelete: KeyAction.cascade)();
  // Ссылка на фактор
  TextColumn get factorId =>
      text().references(SleepFactors, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {id};
}

// --- ТАБЛИЦА: НАСТРОЙКИ СНА ---
class SleepGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get targetWakeHour => integer().withDefault(const Constant(8))();
  IntColumn get targetWakeMinute => integer().withDefault(const Constant(0))();
  RealColumn get targetDuration => real().withDefault(const Constant(8.5))();
}
