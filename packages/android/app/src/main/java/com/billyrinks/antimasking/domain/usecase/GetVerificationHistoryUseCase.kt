package com.billyrinks.antimasking.domain.usecase

import com.billyrinks.antimasking.domain.model.CallVerification
import com.billyrinks.antimasking.domain.repository.AntiMaskingRepository
import javax.inject.Inject

/**
 * Use case for getting verification history
 */
class GetVerificationHistoryUseCase @Inject constructor(
    private val repository: AntiMaskingRepository
) {
    suspend operator fun invoke(
        limit: Int = 20,
        offset: Int = 0,
        maskingDetectedOnly: Boolean = false
    ): Result<List<CallVerification>> {
        return repository.getVerifications(
            limit = limit,
            offset = offset,
            maskingDetected = if (maskingDetectedOnly) true else null
        )
    }
}
