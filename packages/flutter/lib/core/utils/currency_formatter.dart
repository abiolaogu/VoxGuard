import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Currency formatting utilities
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Format as Naira
  static String formatNaira(
    double amount, {
    bool showSymbol = true,
    bool showCode = false,
    int decimals = 2,
  }) {
    final formatter = NumberFormat.currency(
      locale: 'en_NG',
      symbol: showSymbol ? AppConstants.nairaSymbol : '',
      decimalDigits: decimals,
    );
    final formatted = formatter.format(amount);
    if (showCode) {
      return '$formatted ${AppConstants.nigerianCurrencyCode}';
    }
    return formatted;
  }

  /// Format with any currency
  static String formatCurrency(
    double amount,
    String currencyCode, {
    bool showSymbol = true,
    int decimals = 2,
  }) {
    final symbol = showSymbol
        ? (AppConstants.currencySymbols[currencyCode] ?? currencyCode)
        : '';

    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimals,
    );
    return formatter.format(amount);
  }

  /// Format compact (e.g., 1.5M, 2.3K)
  static String formatCompact(double amount, {String? currencySymbol}) {
    final formatter = NumberFormat.compact();
    final formatted = formatter.format(amount);
    if (currencySymbol != null) {
      return '$currencySymbol$formatted';
    }
    return formatted;
  }

  /// Format Naira compact
  static String formatNairaCompact(double amount) {
    if (amount >= 1000000000) {
      return '${AppConstants.nairaSymbol}${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '${AppConstants.nairaSymbol}${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${AppConstants.nairaSymbol}${(amount / 1000).toStringAsFixed(1)}K';
    }
    return formatNaira(amount, decimals: 0);
  }

  /// Parse currency string to double
  static double? parse(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^\d.-]'), '');
    return double.tryParse(cleaned);
  }

  /// Get currency symbol
  static String getSymbol(String currencyCode) {
    return AppConstants.currencySymbols[currencyCode] ?? currencyCode;
  }

  /// Format exchange rate
  static String formatExchangeRate(
    double rate, {
    String fromCurrency = 'USD',
    String toCurrency = 'NGN',
  }) {
    final fromSymbol = getSymbol(fromCurrency);
    final toSymbol = getSymbol(toCurrency);
    return '1 $fromSymbol = ${formatNumber(rate)} $toSymbol';
  }

  /// Format plain number
  static String formatNumber(double number, {int decimals = 2}) {
    final formatter = NumberFormat.decimalPattern();
    if (decimals == 0) {
      return formatter.format(number.round());
    }
    return number.toStringAsFixed(decimals);
  }

  /// Format percentage
  static String formatPercent(double value, {int decimals = 1}) {
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }
}
