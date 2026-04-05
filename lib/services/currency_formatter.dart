class CurrencyFormatter {
  /// Formats a number using the South Asian (Pakistan/India) grouping:
  /// 1,23,456; 12,34,567; etc. Fractions are optional (0 or 2 decimals).
  static String pk(num amount, {int decimalDigits = 0}) {
    final negative = amount < 0;
    final abs = amount.abs();

    final intPart = abs.floor();
    final fracPart = abs - intPart;

    final intStr = intPart.toString();
    if (intStr.length <= 3) {
      return (negative ? '-' : '') + _withFraction(intStr, fracPart, decimalDigits);
    }

    final last3 = intStr.substring(intStr.length - 3);
    String rest = intStr.substring(0, intStr.length - 3);

    final groups = <String>[];
    while (rest.length > 2) {
      groups.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) {
      groups.insert(0, rest);
    }

    final formattedInt = '${groups.join(",")},$last3';
    final withFrac = _withFraction(formattedInt, fracPart, decimalDigits);
    return negative ? '-$withFrac' : withFrac;
  }

  static String _withFraction(String intPart, num fracPart, int decimalDigits) {
    if (decimalDigits <= 0 || fracPart == 0) return intPart;
    final factor = num.parse('1' + ('0' * decimalDigits));
    final rounded = (fracPart * factor).round();
    final fracStr = rounded.toString().padLeft(decimalDigits, '0');
    return '$intPart.$fracStr';
  }
}

