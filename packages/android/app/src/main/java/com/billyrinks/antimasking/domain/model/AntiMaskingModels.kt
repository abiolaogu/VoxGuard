package com.billyrinks.antimasking.domain.model

import java.time.Instant

/**
 * Domain model for call verification
 */
data class CallVerification(
    val id: String,
    val callerNumber: String,
    val calleeNumber: String,
    val originalCli: String,
    val detectedCli: String? = null,
    val maskingDetected: Boolean,
    val confidenceScore: Double,
    val status: VerificationStatus,
    val gatewayName: String? = null,
    val detectedMno: String? = null,
    val verifiedAt: Instant,
    val createdAt: Instant
) {
    val riskLevel: RiskLevel
        get() = when {
            confidenceScore >= 0.9 -> RiskLevel.CRITICAL
            confidenceScore >= 0.7 -> RiskLevel.HIGH
            confidenceScore >= 0.5 -> RiskLevel.MEDIUM
            else -> RiskLevel.LOW
        }

    val isSafe: Boolean
        get() = !maskingDetected && confidenceScore < 0.5

    val isSuspicious: Boolean
        get() = maskingDetected || confidenceScore >= 0.7
}

enum class VerificationStatus {
    PENDING,
    VERIFYING,
    VERIFIED,
    MASKING_DETECTED,
    FAILED
}

enum class RiskLevel {
    LOW,
    MEDIUM,
    HIGH,
    CRITICAL
}

/**
 * Domain model for fraud alert
 */
data class FraudAlert(
    val id: String,
    val verificationId: String,
    val severity: AlertSeverity,
    val title: String,
    val message: String,
    val callerNumber: String,
    val detectedMno: String? = null,
    val isAcknowledged: Boolean,
    val createdAt: Instant
)

enum class AlertSeverity {
    LOW,
    MEDIUM,
    HIGH,
    CRITICAL
}

/**
 * Domain model for MNO (Mobile Network Operator)
 */
enum class NigerianMno(val displayName: String, val prefixes: List<String>) {
    MTN("MTN Nigeria", listOf("0703", "0706", "0803", "0806", "0810", "0813", "0814", "0816", "0903", "0906", "0913")),
    GLO("Globacom", listOf("0705", "0805", "0807", "0811", "0815", "0905")),
    AIRTEL("Airtel Nigeria", listOf("0701", "0708", "0802", "0808", "0812", "0901", "0902", "0904", "0907", "0912")),
    NINE_MOBILE("9mobile", listOf("0809", "0817", "0818", "0908", "0909")),
    UNKNOWN("Unknown", emptyList());

    companion object {
        fun fromPhoneNumber(phoneNumber: String): NigerianMno {
            val normalized = phoneNumber.replace(Regex("[^0-9]"), "")
            val prefix = when {
                normalized.startsWith("234") && normalized.length >= 7 -> "0${normalized.substring(3, 6)}"
                normalized.startsWith("0") && normalized.length >= 4 -> normalized.substring(0, 4)
                else -> return UNKNOWN
            }
            
            return entries.find { mno ->
                mno.prefixes.any { prefix.startsWith(it) }
            } ?: UNKNOWN
        }
    }
}
