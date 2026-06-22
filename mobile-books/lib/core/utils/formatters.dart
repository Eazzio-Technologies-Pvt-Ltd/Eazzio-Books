import 'package:intl/intl.dart';

class AppFormatters {
  // Date formatting: e.g. "2026-06-19" -> "19 Jun 2026"
  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dateTime = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(dateTime);
    } catch (_) {
      return dateStr;
    }
  }

  static String formatDateVal(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Currency formatting: default to INR (₹)
  static String formatCurrency(double amount, {String symbol = '₹'}) {
    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: symbol,
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  // Large compact numbers (e.g., for charts/KPI stats)
  static String formatCompact(double amount) {
    final format = NumberFormat.compact(locale: 'en_IN');
    return format.format(amount);
  }

  // Number decimal formatting
  static String formatNumber(double number) {
    final format = NumberFormat('#,##,##0.00', 'en_IN');
    return format.format(number);
  }
}
