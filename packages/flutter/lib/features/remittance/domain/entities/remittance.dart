import 'package:equatable/equatable.dart';

/// Remittance transaction entity
class RemittanceTransaction extends Equatable {
  final String id;
  final String senderId;
  final String recipientId;
  final double amountSent;
  final String currencySent;
  final double amountReceived;
  final String currencyReceived;
  final double exchangeRate;
  final double fee;
  final TransactionStatus status;
  final String? reference;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Recipient? recipient;
  final PaymentMethod? paymentMethod;

  const RemittanceTransaction({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.amountSent,
    required this.currencySent,
    required this.amountReceived,
    required this.currencyReceived,
    required this.exchangeRate,
    required this.fee,
    required this.status,
    this.reference,
    required this.createdAt,
    this.completedAt,
    this.recipient,
    this.paymentMethod,
  });

  /// Total amount charged (sent + fee)
  double get totalCharged => amountSent + fee;

  /// Check if transaction is complete
  bool get isComplete => status == TransactionStatus.completed;

  /// Check if transaction is pending
  bool get isPending => status == TransactionStatus.pending ||
      status == TransactionStatus.processing;

  @override
  List<Object?> get props => [
        id,
        senderId,
        recipientId,
        amountSent,
        currencySent,
        amountReceived,
        currencyReceived,
        exchangeRate,
        fee,
        status,
        createdAt,
      ];
}

/// Transaction status enum
enum TransactionStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
}

/// Extension for transaction status
extension TransactionStatusExtension on TransactionStatus {
  String get label {
    switch (this) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.processing:
        return 'Processing';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
      case TransactionStatus.refunded:
        return 'Refunded';
    }
  }
}

/// Recipient entity
class Recipient extends Equatable {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? email;
  final String bankCode;
  final String bankName;
  final String accountNumber;
  final String? accountName;
  final bool isVerified;
  final DateTime createdAt;

  const Recipient({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.email,
    required this.bankCode,
    required this.bankName,
    required this.accountNumber,
    this.accountName,
    required this.isVerified,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  String get maskedAccountNumber {
    if (accountNumber.length <= 4) return accountNumber;
    final visible = accountNumber.substring(accountNumber.length - 4);
    return '**** **** $visible';
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        firstName,
        lastName,
        phoneNumber,
        bankCode,
        accountNumber,
      ];
}

/// Payment method entity
class PaymentMethod extends Equatable {
  final String id;
  final PaymentMethodType type;
  final String? cardLast4;
  final String? cardBrand;
  final String? bankName;
  final bool isDefault;

  const PaymentMethod({
    required this.id,
    required this.type,
    this.cardLast4,
    this.cardBrand,
    this.bankName,
    required this.isDefault,
  });

  String get displayName {
    switch (type) {
      case PaymentMethodType.card:
        return '${cardBrand ?? 'Card'} •••• $cardLast4';
      case PaymentMethodType.bankTransfer:
        return bankName ?? 'Bank Transfer';
      case PaymentMethodType.wallet:
        return 'Wallet Balance';
    }
  }

  @override
  List<Object?> get props => [id, type, cardLast4, cardBrand, bankName, isDefault];
}

/// Payment method type
enum PaymentMethodType {
  card,
  bankTransfer,
  wallet,
}

/// Exchange rate entity
class ExchangeRate extends Equatable {
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final double fee;
  final double feePercent;
  final DateTime validUntil;

  const ExchangeRate({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.fee,
    required this.feePercent,
    required this.validUntil,
  });

  /// Calculate amount to receive
  double calculateReceived(double sendAmount) {
    return sendAmount * rate;
  }

  /// Calculate fee
  double calculateFee(double sendAmount) {
    return sendAmount * (feePercent / 100);
  }

  /// Check if rate is still valid
  bool get isValid => DateTime.now().isBefore(validUntil);

  @override
  List<Object?> get props => [fromCurrency, toCurrency, rate, fee, validUntil];
}

/// Corridor (remittance route) entity
class RemittanceCorridor extends Equatable {
  final String id;
  final String sourceCountry;
  final String sourceCurrency;
  final String destinationCountry;
  final String destinationCurrency;
  final double minAmount;
  final double maxAmount;
  final bool isActive;

  const RemittanceCorridor({
    required this.id,
    required this.sourceCountry,
    required this.sourceCurrency,
    required this.destinationCountry,
    required this.destinationCurrency,
    required this.minAmount,
    required this.maxAmount,
    required this.isActive,
  });

  String get displayName => '$sourceCountry ($sourceCurrency) → $destinationCountry ($destinationCurrency)';

  @override
  List<Object?> get props => [id, sourceCountry, destinationCountry, sourceCurrency, destinationCurrency];
}
