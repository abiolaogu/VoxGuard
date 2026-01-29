package com.billyrinks.antimasking.domain.usecase

import com.billyrinks.antimasking.domain.model.CallVerification
import com.billyrinks.antimasking.domain.repository.AntiMaskingRepository
import javax.inject.Inject

/**
 * Use case for verifying a call
 */
class VerifyCallUseCase @Inject constructor(
    private val repository: AntiMaskingRepository
) {
    suspend operator fun invoke(
        callerNumber: String,
        calleeNumber: String
    ): Result<CallVerification> {
        // Validate phone numbers
        if (!isValidNigerianNumber(callerNumber)) {
            return Result.failure(IllegalArgumentException("Invalid caller number format"))
        }
        if (!isValidNigerianNumber(calleeNumber)) {
            return Result.failure(IllegalArgumentException("Invalid callee number format"))
        }

        return repository.verifyCall(
            callerNumber = normalizePhoneNumber(callerNumber),
            calleeNumber = normalizePhoneNumber(calleeNumber)
        )
    }

    private fun isValidNigerianNumber(number: String): Boolean {
        val normalized = number.replace(Regex("[^0-9]"), "")
        return when {
            normalized.startsWith("234") && normalized.length == 13 -> true
            normalized.startsWith("0") && normalized.length == 11 -> true
            else -> false
        }
    }

    private fun normalizePhoneNumber(number: String): String {
        val cleaned = number.replace(Regex("[^0-9]"), "")
        return if (cleaned.startsWith("0")) {
            "+234${cleaned.substring(1)}"
        } else if (cleaned.startsWith("234")) {
            "+$cleaned"
        } else {
            "+234$cleaned"
        }
    }
}
