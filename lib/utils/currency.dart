import 'package:intl/intl.dart';

class CurrencyFormatter {
  const CurrencyFormatter._();

  static String format(double value, [String currencyCode = 'INR']) {
    final normalized = currencyCode.toUpperCase();
    final symbol = normalized == 'INR' ? '₹' : normalized == 'USD' ? '\$' : normalized;
    final locale = normalized == 'INR' ? 'en_IN' : 'en_US';

    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: 2,
    );

    final formatted = formatter.format(value);
    if (normalized == 'INR' && value < 0) {
      return '-₹${formatter.format(value.abs())}'.replaceFirst('₹', '');
    }
    return formatted;
  }
}
