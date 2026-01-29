package com.billyrinks.antimasking.domain.repository

import com.billyrinks.antimasking.domain.model.CallVerification
import com.billyrinks.antimasking.domain.model.FraudAlert
import kotlinx.coroutines.flow.Flow

/**
 * Repository interface for anti-masking operations
 */
interface AntiMaskingRepository {

    /**
     * Verify a call between caller and callee numbers
     */
    suspend fun verifyCall(
        callerNumber: String,
        calleeNumber: String
    ): Result<CallVerification>

    /**
     * Get verification history with optional filtering
     */
    suspend fun getVerifications(
        limit: Int = 20,
        offset: Int = 0,
        maskingDetected: Boolean? = null
    ): Result<List<CallVerification>>

    /**
     * Get a specific verification by ID
     */
    suspend fun getVerificationById(id: String): Result<CallVerification>

    /**
     * Subscribe to real-time verifications
     */
    fun observeVerifications(): Flow<CallVerification>

    /**
     * Report masking to NCC
     */
    suspend fun reportMasking(
        verificationId: String,
        additionalInfo: String? = null
    ): Result<Unit>

    /**
     * Get fraud alerts
     */
    suspend fun getFraudAlerts(
        limit: Int = 20,
        isAcknowledged: Boolean? = null
    ): Result<List<FraudAlert>>

    /**
     * Subscribe to real-time fraud alerts
     */
    fun observeFraudAlerts(): Flow<FraudAlert>

    /**
     * Acknowledge a fraud alert
     */
    suspend fun acknowledgeFraudAlert(alertId: String): Result<Unit>
}
