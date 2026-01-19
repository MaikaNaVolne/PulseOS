extension CurrencyFormatter on double {
  String toCurrencyString() {
    // Убираем .00 если число целое
    if (this % 1 == 0) {
      return toInt().toString();
    }
    return toStringAsFixed(2);
  }
}
