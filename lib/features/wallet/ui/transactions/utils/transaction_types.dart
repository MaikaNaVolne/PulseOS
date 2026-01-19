import 'package:flutter/material.dart';
import '../../../../../core/theme/pulse_theme.dart';

enum TransactionType {
  expense,
  income,
  transfer,
  transferPerson;

  String get label {
    switch (this) {
      case TransactionType.expense:
        return "Расход";
      case TransactionType.income:
        return "Доход";
      case TransactionType.transfer:
        return "Перевод";
      case TransactionType.transferPerson:
        return "Людям";
    }
  }

  String get subtitle {
    switch (this) {
      case TransactionType.expense:
        return "РАСХОД";
      case TransactionType.income:
        return "ДОХОД";
      case TransactionType.transfer:
        return "ПЕРЕВОД";
      case TransactionType.transferPerson:
        return "ЛЮДЯМ";
    }
  }

  Color get color {
    switch (this) {
      case TransactionType.expense:
        return PulseColors.red;
      case TransactionType.income:
        return PulseColors.green;
      case TransactionType.transfer:
        return PulseColors.blue;
      case TransactionType.transferPerson:
        return PulseColors.purple;
    }
  }

  // Для совместимости со старым кодом базы данных (String)
  String get dbValue {
    switch (this) {
      case TransactionType.transferPerson:
        return 'transfer_person';
      default:
        return name; // 'expense', 'income', 'transfer'
    }
  }
}
