import 'package:flutter_test/flutter_test.dart';

import 'package:acm_mobile/core/utils/phone_formatter.dart';
import 'package:acm_mobile/core/utils/currency_formatter.dart';

/// Test helper utilities
class TestHelper {
  TestHelper._();

  /// Create a verified phone number for testing
  static String createTestPhone({
    String mno = 'MTN',
    String suffix = '1234567',
  }) {
    final prefixes = {
      'MTN': '0803',
      'Glo': '0805',
      'Airtel': '0802',
      '9mobile': '0809',
    };
    final prefix = prefixes[mno] ?? '0803';
    return '$prefix$suffix';
  }

  /// Create test verification data
  static Map<String, dynamic> createTestVerificationJson({
    String id = 'test-id',
    String callerNumber = '08031234567',
    String calleeNumber = '08051234567',
    bool maskingDetected = false,
    double confidenceScore = 0.1,
    String status = 'verified',
  }) {
    return {
      'id': id,
      'caller_number': callerNumber,
      'callee_number': calleeNumber,
      'original_cli': callerNumber,
      'detected_cli': maskingDetected ? '08099999999' : null,
      'masking_detected': maskingDetected,
      'confidence_score': confidenceScore,
      'status': status,
      'verified_at': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Create test transaction data
  static Map<String, dynamic> createTestTransactionJson({
    String id = 'tx-id',
    double amountSent = 100.0,
    String currencySent = 'USD',
    double amountReceived = 165000.0,
    String currencyReceived = 'NGN',
    String status = 'completed',
  }) {
    return {
      'id': id,
      'sender_id': 'sender-id',
      'recipient_id': 'recipient-id',
      'amount_sent': amountSent,
      'currency_sent': currencySent,
      'amount_received': amountReceived,
      'currency_received': currencyReceived,
      'exchange_rate': amountReceived / amountSent,
      'fee': amountSent * 0.01,
      'status': status,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Wait for async operations
  static Future<void> pump([int milliseconds = 100]) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
  }
}

void main() {
  group('PhoneFormatter Tests', () {
    test('should detect MTN numbers correctly', () {
      expect(PhoneFormatter.detectMNO('08031234567'), 'MTN');
      expect(PhoneFormatter.detectMNO('08061234567'), 'MTN');
      expect(PhoneFormatter.detectMNO('07031234567'), 'MTN');
    });

    test('should detect Glo numbers correctly', () {
      expect(PhoneFormatter.detectMNO('08051234567'), 'Glo');
      expect(PhoneFormatter.detectMNO('08151234567'), 'Glo');
    });

    test('should detect Airtel numbers correctly', () {
      expect(PhoneFormatter.detectMNO('08021234567'), 'Airtel');
      expect(PhoneFormatter.detectMNO('08081234567'), 'Airtel');
    });

    test('should detect 9mobile numbers correctly', () {
      expect(PhoneFormatter.detectMNO('08091234567'), '9mobile');
      expect(PhoneFormatter.detectMNO('08181234567'), '9mobile');
    });

    test('should validate Nigerian phone numbers', () {
      expect(PhoneFormatter.isValid('08031234567'), true);
      expect(PhoneFormatter.isValid('+2348031234567'), true);
      expect(PhoneFormatter.isValid('2348031234567'), true);
      expect(PhoneFormatter.isValid('08001234567'), false); // Invalid prefix
      expect(PhoneFormatter.isValid('0803123'), false); // Too short
    });

    test('should format phone numbers correctly', () {
      expect(
        PhoneFormatter.format('08031234567', format: PhoneFormat.international),
        '+234 803 123 4567',
      );
      expect(
        PhoneFormatter.format('08031234567', format: PhoneFormat.local),
        '0803 123 4567',
      );
      expect(
        PhoneFormatter.format('08031234567', format: PhoneFormat.compact),
        '+2348031234567',
      );
    });

    test('should convert to E164 format', () {
      expect(PhoneFormatter.toE164('08031234567'), '+2348031234567');
      expect(PhoneFormatter.toE164('+2348031234567'), '+2348031234567');
    });

    test('should mask phone numbers', () {
      expect(PhoneFormatter.mask('08031234567'), '*******4567');
      expect(PhoneFormatter.mask('08031234567', visibleDigits: 2), '*********67');
    });
  });

  group('CurrencyFormatter Tests', () {
    test('should format Naira correctly', () {
      expect(CurrencyFormatter.formatNaira(1500000), contains('1,500,000'));
      expect(CurrencyFormatter.formatNaira(1500000), contains('₦'));
    });

    test('should format Naira compact correctly', () {
      expect(CurrencyFormatter.formatNairaCompact(1500000), '₦1.5M');
      expect(CurrencyFormatter.formatNairaCompact(1500000000), '₦1.5B');
      expect(CurrencyFormatter.formatNairaCompact(1500), '₦1.5K');
    });

    test('should format different currencies', () {
      expect(CurrencyFormatter.formatCurrency(100, 'USD'), contains('\$'));
      expect(CurrencyFormatter.formatCurrency(100, 'GBP'), contains('£'));
      expect(CurrencyFormatter.formatCurrency(100, 'EUR'), contains('€'));
    });

    test('should parse currency strings', () {
      expect(CurrencyFormatter.parse('₦1,500,000'), 1500000);
      expect(CurrencyFormatter.parse('\$100.50'), 100.50);
    });

    test('should get currency symbols', () {
      expect(CurrencyFormatter.getSymbol('NGN'), '₦');
      expect(CurrencyFormatter.getSymbol('USD'), '\$');
      expect(CurrencyFormatter.getSymbol('GBP'), '£');
    });

    test('should format percentages', () {
      expect(CurrencyFormatter.formatPercent(0.1568), '15.7%');
      expect(CurrencyFormatter.formatPercent(0.9, decimals: 0), '90%');
    });
  });

  group('TestHelper', () {
    test('should create test phone with correct MNO', () {
      final mtnPhone = TestHelper.createTestPhone(mno: 'MTN');
      expect(PhoneFormatter.detectMNO(mtnPhone), 'MTN');

      final gloPhone = TestHelper.createTestPhone(mno: 'Glo');
      expect(PhoneFormatter.detectMNO(gloPhone), 'Glo');
    });

    test('should create test verification json', () {
      final json = TestHelper.createTestVerificationJson(
        maskingDetected: true,
        confidenceScore: 0.95,
      );

      expect(json['masking_detected'], true);
      expect(json['confidence_score'], 0.95);
      expect(json['detected_cli'], isNotNull);
    });

    test('should create test transaction json', () {
      final json = TestHelper.createTestTransactionJson(
        amountSent: 100,
        amountReceived: 165000,
      );

      expect(json['exchange_rate'], 1650);
      expect(json['fee'], 1.0);
    });
  });
}
