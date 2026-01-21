import '../../ui/transactions/utils/transaction_types.dart';

class TransactionFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final TransactionType? type;
  final String? accountId;
  final List<String> categoryIds;
  final String? tagQuery;

  const TransactionFilter({
    this.startDate,
    this.endDate,
    this.type,
    this.accountId,
    this.categoryIds = const [],
    this.tagQuery,
  });

  bool get isActive =>
      startDate != null ||
      type != null ||
      accountId != null ||
      categoryIds.isNotEmpty ||
      tagQuery != null;

  TransactionFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    String? accountId,
    List<String>? categoryIds,
    String? tagQuery,
    bool clearDates = false,
  }) {
    return TransactionFilter(
      // Если clearDates = true, зануляем даты, иначе берем новые или старые
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),

      // Логика переключения
      type: type == this.type ? null : (type ?? this.type),
      accountId: accountId == this.accountId
          ? null
          : (accountId ?? this.accountId),

      categoryIds: categoryIds ?? this.categoryIds,
      tagQuery: tagQuery ?? this.tagQuery,
    );
  }

  factory TransactionFilter.empty() => const TransactionFilter();
}
