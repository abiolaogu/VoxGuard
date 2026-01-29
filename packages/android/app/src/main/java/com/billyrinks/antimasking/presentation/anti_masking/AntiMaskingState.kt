package com.billyrinks.antimasking.presentation.anti_masking

import com.billyrinks.antimasking.domain.model.CallVerification
import com.billyrinks.antimasking.domain.model.FraudAlert
import com.billyrinks.antimasking.domain.model.NigerianMno

/**
 * UI State for Anti-Masking feature
 */
data class AntiMaskingState(
    // Form state
    val callerNumber: String = "",
    val calleeNumber: String = "",
    val callerMno: NigerianMno = NigerianMno.UNKNOWN,
    val calleeMno: NigerianMno = NigerianMno.UNKNOWN,

    // Verification state
    val isVerifying: Boolean = false,
    val latestVerification: CallVerification? = null,
    val verificationHistory: List<CallVerification> = emptyList(),

    // Alerts state
    val fraudAlerts: List<FraudAlert> = emptyList(),
    val unacknowledgedAlertCount: Int = 0,

    // Loading and error states
    val isLoading: Boolean = false,
    val isLoadingHistory: Boolean = false,
    val error: String? = null,

    // Filter state
    val showMaskingDetectedOnly: Boolean = false
) {
    val canVerify: Boolean
        get() = callerNumber.length >= 10 && calleeNumber.length >= 10 && !isVerifying

    val hasUnacknowledgedAlerts: Boolean
        get() = unacknowledgedAlertCount > 0
}
