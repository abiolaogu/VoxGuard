package com.billyrinks.antimasking.domain.model

import java.math.BigDecimal
import java.time.Instant

/**
 * Domain model for remittance transaction
 */
data class RemittanceTransaction(
    val id: String,
    val senderId: String,
    val recipientId: String,
    val recipientName: String,
    val amountSent: BigDecimal,
    val currencySent: Currency,
    val amountReceived: BigDecimal,
    val currencyReceived: Currency,
    val exchangeRate: BigDecimal,
    val fee: BigDecimal,
    val status: TransactionStatus,
    val reference: String,
    val createdAt: Instant,
    val completedAt: Instant? = null
) {
    val totalCost: BigDecimal
        get() = amountSent + fee
}

enum class TransactionStatus {
    PENDING,
    PROCESSING,
    COMPLETED,
    FAILED,
    CANCELLED
}

/**
 * Domain model for exchange rate
 */
data class ExchangeRate(
    val sourceCurrency: Currency,
    val targetCurrency: Currency,
    val rate: BigDecimal,
    val inverseRate: BigDecimal,
    val timestamp: Instant
)

/**
 * Domain model for recipient
 */
data class Recipient(
    val id: String,
    val fullName: String,
    val phoneNumber: String,
    val bankName: String? = null,
    val bankCode: String? = null,
    val accountNumber: String? = null,
    val state: String? = null,
    val isFavorite: Boolean = false,
    val createdAt: Instant
)

/**
 * Supported currencies
 */
enum class Currency(val code: String, val symbol: String, val name: String) {
    NGN("NGN", "₦", "Nigerian Naira"),
    USD("USD", "$", "US Dollar"),
    GBP("GBP", "£", "British Pound"),
    EUR("EUR", "€", "Euro"),
    CAD("CAD", "C$", "Canadian Dollar"),
    ZAR("ZAR", "R", "South African Rand");

    companion object {
        fun fromCode(code: String): Currency {
            return entries.find { it.code.equals(code, ignoreCase = true) } ?: USD
        }
    }
}

/**
 * Domain model for corridor (remittance route)
 */
data class Corridor(
    val id: String,
    val sourceCurrency: Currency,
    val targetCurrency: Currency,
    val minAmount: BigDecimal,
    val maxAmount: BigDecimal,
    val feePercentage: BigDecimal,
    val flatFee: BigDecimal,
    val isActive: Boolean
) {
    fun calculateFee(amount: BigDecimal): BigDecimal {
        return (amount * feePercentage / BigDecimal(100)) + flatFee
    }
}

/**
 * Nigerian banks
 */
data class NigerianBank(
    val code: String,
    val name: String,
    val shortName: String
) {
    companion object {
        val allBanks = listOf(
            NigerianBank("044", "Access Bank", "Access"),
            NigerianBank("023", "Citibank Nigeria", "Citibank"),
            NigerianBank("050", "Ecobank Nigeria", "Ecobank"),
            NigerianBank("070", "Fidelity Bank", "Fidelity"),
            NigerianBank("011", "First Bank of Nigeria", "First Bank"),
            NigerianBank("214", "First City Monument Bank", "FCMB"),
            NigerianBank("058", "Guaranty Trust Bank", "GTBank"),
            NigerianBank("030", "Heritage Bank", "Heritage"),
            NigerianBank("301", "Jaiz Bank", "Jaiz"),
            NigerianBank("082", "Keystone Bank", "Keystone"),
            NigerianBank("101", "Providus Bank", "Providus"),
            NigerianBank("076", "Polaris Bank", "Polaris"),
            NigerianBank("221", "Stanbic IBTC Bank", "Stanbic"),
            NigerianBank("232", "Sterling Bank", "Sterling"),
            NigerianBank("032", "Union Bank of Nigeria", "Union Bank"),
            NigerianBank("033", "United Bank for Africa", "UBA"),
            NigerianBank("215", "Unity Bank", "Unity"),
            NigerianBank("035", "Wema Bank", "Wema"),
            NigerianBank("057", "Zenith Bank", "Zenith"),
            NigerianBank("999", "Kuda Bank", "Kuda"),
            NigerianBank("999", "OPay", "OPay"),
            NigerianBank("999", "PalmPay", "PalmPay"),
            NigerianBank("999", "Moniepoint", "Moniepoint")
        )
    }
}
