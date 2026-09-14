// Unit tests for formatPKR, the currency formatter actually used across the
// payment, invoice, and expense screens (lib/services/currency_format.dart).
// Getting this wrong would misrepresent real money amounts to contractors,
// so it's worth pinning down with tests rather than trusting it silently.

import 'package:flutter_test/flutter_test.dart';
import 'package:track_site_pro_app/services/currency_format.dart';

void main() {
  group('formatPKR', () {
    test('groups amounts using the Pakistani/Indian digit grouping', () {
      expect(formatPKR(1234567), '12,34,567');
    });

    test('formats small amounts without extra grouping separators', () {
      expect(formatPKR(1000), '1,000');
    });

    test('formats zero', () {
      expect(formatPKR(0), '0');
    });

    test('drops decimals by default', () {
      expect(formatPKR(1234567.89), '12,34,568');
    });

    test('respects an explicit fractionDigits count', () {
      expect(formatPKR(1234567.5, fractionDigits: 2), '12,34,567.50');
    });

    test('does not leave a stray currency symbol or leading space', () {
      final result = formatPKR(50000);
      expect(result, isNot(contains('Rs')));
      expect(result, isNot(startsWith(' ')));
    });
  });
}
