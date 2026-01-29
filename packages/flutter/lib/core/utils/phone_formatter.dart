import '../constants/app_constants.dart';

/// Phone number formatting and validation utilities
class PhoneFormatter {
  PhoneFormatter._();

  /// Nigerian country code
  static const String _countryCode = '+234';

  /// Format Nigerian phone number
  static String format(
    String phone, {
    PhoneFormat format = PhoneFormat.international,
  }) {
    final cleaned = _cleanNumber(phone);
    final local = _toLocalFormat(cleaned);

    if (local.length != 11) {
      return phone; // Return original if invalid
    }

    switch (format) {
      case PhoneFormat.international:
        return '$_countryCode ${local.substring(1, 4)} ${local.substring(4, 7)} ${local.substring(7)}';
      case PhoneFormat.local:
        return '${local.substring(0, 4)} ${local.substring(4, 7)} ${local.substring(7)}';
      case PhoneFormat.compact:
        return '$_countryCode${local.substring(1)}';
      case PhoneFormat.plain:
        return local;
    }
  }

  /// Validate Nigerian phone number
  static bool isValid(String phone) {
    final cleaned = _cleanNumber(phone);
    final local = _toLocalFormat(cleaned);

    if (local.length != 11 || !local.startsWith('0')) {
      return false;
    }

    return detectMNO(local) != null;
  }

  /// Detect Mobile Network Operator
  static String? detectMNO(String phone) {
    final cleaned = _cleanNumber(phone);
    final local = _toLocalFormat(cleaned);

    if (local.length < 4) return null;

    final prefix = local.substring(0, 4);

    for (final entry in AppConstants.mnoPatterns.entries) {
      if (entry.value.contains(prefix)) {
        return entry.key;
      }
    }

    return null;
  }

  /// Normalize to E.164 format (+2348012345678)
  static String? toE164(String phone) {
    final cleaned = _cleanNumber(phone);
    final local = _toLocalFormat(cleaned);

    if (!isValid(local)) {
      return null;
    }

    return '$_countryCode${local.substring(1)}';
  }

  /// Normalize to local format (08012345678)
  static String? toLocal(String phone) {
    final cleaned = _cleanNumber(phone);
    final local = _toLocalFormat(cleaned);

    if (!isValid(local)) {
      return null;
    }

    return local;
  }

  /// Get phone segment for display
  static PhoneSegments? getSegments(String phone) {
    final cleaned = _cleanNumber(phone);
    final local = _toLocalFormat(cleaned);

    if (local.length != 11) return null;

    return PhoneSegments(
      prefix: local.substring(0, 4),
      middle: local.substring(4, 7),
      suffix: local.substring(7),
      mno: detectMNO(local),
    );
  }

  /// Clean phone number (remove non-digits except +)
  static String _cleanNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  /// Convert to local format
  static String _toLocalFormat(String phone) {
    if (phone.startsWith('+234')) {
      return '0${phone.substring(4)}';
    }
    if (phone.startsWith('234')) {
      return '0${phone.substring(3)}';
    }
    return phone;
  }

  /// Mask phone number for privacy
  static String mask(String phone, {int visibleDigits = 4}) {
    final cleaned = _cleanNumber(phone);
    if (cleaned.length <= visibleDigits) {
      return cleaned;
    }

    final visible = cleaned.substring(cleaned.length - visibleDigits);
    final masked = '*' * (cleaned.length - visibleDigits);
    return masked + visible;
  }
}

/// Phone number format options
enum PhoneFormat {
  /// +234 803 123 4567
  international,

  /// 0803 123 4567
  local,

  /// +2348031234567
  compact,

  /// 08031234567
  plain,
}

/// Phone number segments
class PhoneSegments {
  final String prefix;
  final String middle;
  final String suffix;
  final String? mno;

  const PhoneSegments({
    required this.prefix,
    required this.middle,
    required this.suffix,
    this.mno,
  });

  String get formatted => '$prefix $middle $suffix';
}
