import 'package:intl/intl.dart';

/// Central number/currency formatters. Keeps locale usage consistent.
class Formatters {
  const Formatters._();

  /// Colombian pesos as "$48.000": symbol first, dot as thousands separator.
  /// The explicit pattern is needed because the locale's default puts the
  /// symbol after the amount.
  static final NumberFormat cop = NumberFormat.currency(
    locale: 'es_CO',
    symbol: r'$',
    decimalDigits: 0,
    customPattern: '¤#,##0',
  );

  static final NumberFormat integer = NumberFormat.decimalPattern('es_CO');

  /// Utilities and weights of the model: "0,58", "0,580" and "0,5".
  static final NumberFormat decimal2 = NumberFormat('0.00', 'es_CO');
  static final NumberFormat decimal3 = NumberFormat('0.000', 'es_CO');
  static final NumberFormat compact = NumberFormat('0.##', 'es_CO');

  /// A 0-1 share as "19 %".
  static String percent(double share) => '${(share * 100).round()} %';
}
