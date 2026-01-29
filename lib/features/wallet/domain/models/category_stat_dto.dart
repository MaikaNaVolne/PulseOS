import '../../../../core/database/app_database.dart';

class CategoryStatDto {
  final Category? category; // Null, если категория не указана
  final double totalAmount;
  final int transactionCount;
  final double percentage; // Процент от общих трат (заполняем в провайдере)

  CategoryStatDto({
    required this.category,
    required this.totalAmount,
    required this.transactionCount,
    this.percentage = 0.0,
  });

  // Метод для создания копии с обновленным процентом
  CategoryStatDto copyWith({double? percentage}) {
    return CategoryStatDto(
      category: category,
      totalAmount: totalAmount,
      transactionCount: transactionCount,
      percentage: percentage ?? this.percentage,
    );
  }
}
