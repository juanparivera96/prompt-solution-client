import 'package:intl/intl.dart';

/// Central number/currency formatters. Keeps locale usage consistent.
class Formatters {
  const Formatters._();

  static final NumberFormat cop = NumberFormat.currency(
    locale: 'es_CO',
    symbol: r'$',
    decimalDigits: 0,
  );

  static final NumberFormat integer = NumberFormat.decimalPattern('es_CO');
}
