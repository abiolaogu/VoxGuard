package com.billyrinks.antimasking.presentation.anti_masking

import com.billyrinks.antimasking.domain.model.CallVerification
import com.billyrinks.antimasking.domain.model.FraudAlert

/**
 * Side effects for Anti-Masking feature
 * These are one-time events that should not be stored in state
 */
sealed interface AntiMaskingSideEffect {
    /**
     * Show masking detection alert dialog
     */
    data class ShowMaskingAlert(
        val verification: CallVerification
    ) : AntiMaskingSideEffect

    /**
     * Show fraud alert notification
     */
    data class ShowFraudAlert(
        val alert: FraudAlert
    ) : AntiMaskingSideEffect

    /**
     * Show toast/snackbar message
     */
    data class ShowMessage(
        val message: String,
        val isError: Boolean = false
    ) : AntiMaskingSideEffect

    /**
     * Navigate to verification details
     */
    data class NavigateToVerificationDetails(
        val verificationId: String
    ) : AntiMaskingSideEffect

    /**
     * Trigger haptic feedback for alerts
     */
    data object TriggerHapticFeedback : AntiMaskingSideEffect

    /**
     * Play masking detection sound
     */
    data object PlayMaskingAlertSound : AntiMaskingSideEffect

    /**
     * Report successfully submitted to NCC
     */
    data object ReportSubmittedSuccessfully : AntiMaskingSideEffect
}
