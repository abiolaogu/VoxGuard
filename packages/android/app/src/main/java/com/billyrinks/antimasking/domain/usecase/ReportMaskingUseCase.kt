package com.billyrinks.antimasking.domain.usecase

import com.billyrinks.antimasking.domain.repository.AntiMaskingRepository
import javax.inject.Inject

/**
 * Use case for reporting masking incidents to NCC
 */
class ReportMaskingUseCase @Inject constructor(
    private val repository: AntiMaskingRepository
) {
    suspend operator fun invoke(
        verificationId: String,
        additionalInfo: String? = null
    ): Result<Unit> {
        if (verificationId.isBlank()) {
            return Result.failure(IllegalArgumentException("Verification ID is required"))
        }

        return repository.reportMasking(
            verificationId = verificationId,
            additionalInfo = additionalInfo
        )
    }
}
