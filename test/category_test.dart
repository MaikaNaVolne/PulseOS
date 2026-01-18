import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:pulseos/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('Category Flow: Create -> Add Tag -> Filter by Module', () async {
    // 1. Создаем категории для разных модулей
    final financeId = 'cat_fin_1';
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: financeId,
            name: 'Супермаркет',
            colorHex: '#00FF00',
            moduleType: drift.Value('finance'),
          ),
        );

    final foodId = 'cat_food_1';
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: foodId,
            name: 'Завтрак',
            colorHex: '#FFAA00',
            moduleType: drift.Value('food'),
          ),
        );

    // 2. Создаем тег для финансовой категории
    final tagId = 'tag_1';
    await db
        .into(db.tags)
        .insert(
          TagsCompanion.insert(
            id: tagId,
            categoryId: drift.Value(financeId),
            name: 'Вкусняшки',
          ),
        );

    // 3. ПРОВЕРКА: Фильтрация по модулю
    final financeCats = await (db.select(
      db.categories,
    )..where((t) => t.moduleType.equals('finance'))).get();

    expect(financeCats.length, 1);
    expect(financeCats.first.name, 'Супермаркет');

    // 4. ПРОВЕРКА: Связь тега
    final tagsForCat = await (db.select(
      db.tags,
    )..where((t) => t.categoryId.equals(financeId))).get();

    expect(tagsForCat.length, 1);
    expect(tagsForCat.first.name, 'Вкусняшки');

    print('✅ Category Test Passed!');
  });
}
