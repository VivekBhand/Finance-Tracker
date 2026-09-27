import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/utils/currency.dart';

void main() {
  test('defaults to INR and uses Indian formatting', () {
    expect(CurrencyFormatter.format(1250.5, 'INR'), '₹1,250.50');
    expect(CurrencyFormatter.format(0, 'USD'), '\$0.00');
  });

  test('formats zero and negative values consistently', () {
    expect(CurrencyFormatter.format(-1200.4, 'INR'), '-₹1,200.40');
    expect(CurrencyFormatter.format(0.0, 'INR'), '₹0.00');
  });
}
