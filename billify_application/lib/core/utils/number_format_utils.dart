class NumberFormatUtils {
  /// Formats numbers into compact Indian notations: 1k, 10k, 1L, 10L, 1Cr, etc.
  static String formatCompact(
    num value, {
    bool lowerCase = false,
  }) {
    if (value == 0) return '0';
    final isNegative = value < 0;
    final absVal = value.abs();

    final String unitK = lowerCase ? 'k' : 'k';
    final String unitL = lowerCase ? 'l' : 'L';
    final String unitCr = lowerCase ? 'cr' : 'Cr';

    String result;
    if (absVal >= 10000000) {
      // 1 Crore and above (10,000,000+)
      final cr = absVal / 10000000;
      final decimals = cr >= 100 ? 0 : (cr >= 10 ? 1 : 2);
      result = '${_stripTrailingZeros(cr.toStringAsFixed(decimals))}$unitCr';
    } else if (absVal >= 100000) {
      // 1 Lakh to 99.99 Lakhs (100,000 - 9,999,999)
      final l = absVal / 100000;
      final decimals = l >= 100 ? 0 : (l >= 10 ? 1 : 2);
      result = '${_stripTrailingZeros(l.toStringAsFixed(decimals))}$unitL';
    } else if (absVal >= 1000) {
      // 1 Thousand to 99.99 Thousand (1,000 - 99,999)
      final k = absVal / 1000;
      final decimals = k >= 100 ? 0 : (k >= 10 ? 1 : 2);
      result = '${_stripTrailingZeros(k.toStringAsFixed(decimals))}$unitK';
    } else {
      if (absVal % 1 == 0) {
        result = absVal.toInt().toString();
      } else {
        result = _stripTrailingZeros(absVal.toStringAsFixed(2));
      }
    }

    return isNegative ? '-$result' : result;
  }

  /// Formats currency with ₹ symbol and compact threshold
  static String formatCurrency(
    num value, {
    bool compact = false,
    double compactThreshold = 10000,
    String symbol = '₹',
    bool lowerCase = false,
  }) {
    final absVal = value.abs();
    final isNegative = value < 0;
    final prefix = isNegative ? '-$symbol' : symbol;

    if (compact || absVal >= compactThreshold) {
      return '$prefix${formatCompact(absVal, lowerCase: lowerCase)}';
    }

    final formatted = absVal % 1 == 0
        ? absVal.toInt().toString()
        : absVal.toStringAsFixed(2);
    return '$prefix$formatted';
  }

  /// Formats quantities compactly (e.g. 5, 2.5, 1k, 10k, 1L, 1Cr)
  static String formatQuantity(
    num quantity, {
    bool lowerCase = false,
  }) {
    final absVal = quantity.abs();
    if (absVal < 1000) {
      if (absVal % 1 == 0) {
        return quantity.toInt().toString();
      }
      return _stripTrailingZeros(quantity.toStringAsFixed(3));
    }
    return formatCompact(quantity, lowerCase: lowerCase);
  }

  static String _stripTrailingZeros(String str) {
    if (str.contains('.')) {
      str = str.replaceAll(RegExp(r'0+$'), '');
      if (str.endsWith('.')) {
        str = str.substring(0, str.length - 1);
      }
    }
    return str;
  }
}
