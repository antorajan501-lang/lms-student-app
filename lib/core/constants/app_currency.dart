import 'package:intl/intl.dart';

/// Centralised Indian-Rupee currency helper.
///
/// Usage:
///   AppCurrency.format(1250)      → '₹1,250'
///   AppCurrency.format(0)         → '₹0'
///   AppCurrency.symbol            → '₹'
///   AppCurrency.priceOrFree(0)    → 'Free'
///   AppCurrency.priceOrFree(500)  → '₹500'
class AppCurrency {
  AppCurrency._();

  /// The currency symbol used app-wide.
  static const String symbol = '₹';

  /// Locale used for number formatting (Indian grouping: 1,00,000).
  static const String _locale = 'en_IN';

  static final NumberFormat _fmt =
      NumberFormat.currency(locale: _locale, symbol: symbol, decimalDigits: 0);

  static final NumberFormat _fmtDecimal =
      NumberFormat.currency(locale: _locale, symbol: symbol, decimalDigits: 2);

  /// Formats [amount] as ₹1,250 (no decimal places).
  static String format(num amount) => _fmt.format(amount);

  /// Formats [amount] as ₹1,250.00 (two decimal places).
  static String formatDecimal(num amount) => _fmtDecimal.format(amount);

  /// Returns 'Free' when price is 0, otherwise formats with [format].
  static String priceOrFree(num price) =>
      price <= 0 ? 'Free' : format(price);

  /// Returns 'Free' when price is 0, otherwise formats with [formatDecimal].
  static String priceOrFreeDecimal(num price) =>
      price <= 0 ? 'Free' : formatDecimal(price);
}
