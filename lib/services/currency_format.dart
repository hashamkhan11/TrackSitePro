import 'package:intl/intl.dart';

/// Formats amounts in Pakistani/Indian numbering system (e.g. 12,34,567).
String formatPKR(num value, {int fractionDigits = 0}) {
  final format = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '',
    decimalDigits: fractionDigits,
  );
  final formatted = format.format(value).trim();
  // Remove any leading currency placeholder or spaces
  return formatted.replaceAll(RegExp(r'^[^\d-]+'), '').trim();
}

