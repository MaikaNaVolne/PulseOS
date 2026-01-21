import '../../ui/transactions/utils/transaction_types.dart';

class TransactionFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final TransactionType? type;
  final String? accountId;
  final String? categoryId;
  final String? searchQuery;

  const TransactionFilter({
    this.startDate,
    this.endDate,
    this.type,
    this.accountId,
    this.categoryId,
    this.searchQuery,
  });

  // Проверка: активен ли хоть один фильтр
  bool get isActive =>
      startDate != null ||
      type != null ||
      accountId != null ||
      categoryId != null ||
      (searchQuery?.isNotEmpty ?? false);

  // Метод для удобного копирования состояния
  TransactionFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    String? accountId,
    String? categoryId,
    String? searchQuery,
    bool clearDates = false,
  }) {
    return TransactionFilter(
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      type: type ?? this.type,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  // Начальное состояние
  factory TransactionFilter.empty() => const TransactionFilter();
}
