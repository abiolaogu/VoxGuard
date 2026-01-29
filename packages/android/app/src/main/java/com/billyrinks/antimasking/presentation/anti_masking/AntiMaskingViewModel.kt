package com.billyrinks.antimasking.presentation.anti_masking

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.billyrinks.antimasking.di.IoDispatcher
import com.billyrinks.antimasking.domain.model.NigerianMno
import com.billyrinks.antimasking.domain.repository.AntiMaskingRepository
import com.billyrinks.antimasking.domain.usecase.GetVerificationHistoryUseCase
import com.billyrinks.antimasking.domain.usecase.ReportMaskingUseCase
import com.billyrinks.antimasking.domain.usecase.VerifyCallUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import org.orbitmvi.orbit.ContainerHost
import org.orbitmvi.orbit.container
import org.orbitmvi.orbit.syntax.simple.intent
import org.orbitmvi.orbit.syntax.simple.postSideEffect
import org.orbitmvi.orbit.syntax.simple.reduce
import javax.inject.Inject

/**
 * ViewModel for Anti-Masking feature using Orbit MVI
 */
@HiltViewModel
class AntiMaskingViewModel @Inject constructor(
    private val verifyCallUseCase: VerifyCallUseCase,
    private val getVerificationHistoryUseCase: GetVerificationHistoryUseCase,
    private val reportMaskingUseCase: ReportMaskingUseCase,
    private val repository: AntiMaskingRepository,
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher
) : ContainerHost<AntiMaskingState, AntiMaskingSideEffect>, ViewModel() {

    override val container = container<AntiMaskingState, AntiMaskingSideEffect>(
        initialState = AntiMaskingState()
    ) {
        // Initialize on creation
        loadVerificationHistory()
        loadFraudAlerts()
        observeRealTimeUpdates()
    }

    // =========================================================================
    // Form Input Actions
    // =========================================================================

    fun onCallerNumberChanged(number: String) = intent {
        val mno = NigerianMno.fromPhoneNumber(number)
        reduce {
            state.copy(
                callerNumber = number,
                callerMno = mno,
                error = null
            )
        }
    }

    fun onCalleeNumberChanged(number: String) = intent {
        val mno = NigerianMno.fromPhoneNumber(number)
        reduce {
            state.copy(
                calleeNumber = number,
                calleeMno = mno,
                error = null
            )
        }
    }

    // =========================================================================
    // Verification Actions
    // =========================================================================

    fun verifyCall() = intent {
        if (!state.canVerify) return@intent

        reduce { state.copy(isVerifying = true, error = null) }

        verifyCallUseCase(
            callerNumber = state.callerNumber,
            calleeNumber = state.calleeNumber
        ).onSuccess { verification ->
            reduce {
                state.copy(
                    isVerifying = false,
                    latestVerification = verification,
                    verificationHistory = listOf(verification) + state.verificationHistory
                )
            }

            // Handle masking detection
            if (verification.maskingDetected) {
                postSideEffect(AntiMaskingSideEffect.TriggerHapticFeedback)
                postSideEffect(AntiMaskingSideEffect.PlayMaskingAlertSound)
                postSideEffect(AntiMaskingSideEffect.ShowMaskingAlert(verification))
            } else {
                postSideEffect(
                    AntiMaskingSideEffect.ShowMessage(
                        "Verification complete - No masking detected"
                    )
                )
            }
        }.onFailure { error ->
            reduce {
                state.copy(
                    isVerifying = false,
                    error = error.message ?: "Verification failed"
                )
            }
            postSideEffect(
                AntiMaskingSideEffect.ShowMessage(
                    message = error.message ?: "Verification failed",
                    isError = true
                )
            )
        }
    }

    fun loadVerificationHistory() = intent {
        reduce { state.copy(isLoadingHistory = true) }

        getVerificationHistoryUseCase(
            limit = 20,
            maskingDetectedOnly = state.showMaskingDetectedOnly
        ).onSuccess { verifications ->
            reduce {
                state.copy(
                    isLoadingHistory = false,
                    verificationHistory = verifications
                )
            }
        }.onFailure { error ->
            reduce {
                state.copy(
                    isLoadingHistory = false,
                    error = error.message
                )
            }
        }
    }

    fun toggleMaskingFilter() = intent {
        reduce { state.copy(showMaskingDetectedOnly = !state.showMaskingDetectedOnly) }
        loadVerificationHistory()
    }

    // =========================================================================
    // Reporting Actions
    // =========================================================================

    fun reportToNCC(verificationId: String, additionalInfo: String? = null) = intent {
        reduce { state.copy(isLoading = true) }

        reportMaskingUseCase(
            verificationId = verificationId,
            additionalInfo = additionalInfo
        ).onSuccess {
            reduce { state.copy(isLoading = false) }
            postSideEffect(AntiMaskingSideEffect.ReportSubmittedSuccessfully)
            postSideEffect(
                AntiMaskingSideEffect.ShowMessage(
                    "Report submitted to NCC successfully"
                )
            )
        }.onFailure { error ->
            reduce {
                state.copy(
                    isLoading = false,
                    error = error.message
                )
            }
            postSideEffect(
                AntiMaskingSideEffect.ShowMessage(
                    message = error.message ?: "Failed to submit report",
                    isError = true
                )
            )
        }
    }

    // =========================================================================
    // Fraud Alerts
    // =========================================================================

    fun loadFraudAlerts() = intent {
        repository.getFraudAlerts(
            limit = 20,
            isAcknowledged = null
        ).onSuccess { alerts ->
            reduce {
                state.copy(
                    fraudAlerts = alerts,
                    unacknowledgedAlertCount = alerts.count { !it.isAcknowledged }
                )
            }
        }
    }

    fun acknowledgeFraudAlert(alertId: String) = intent {
        repository.acknowledgeFraudAlert(alertId)
            .onSuccess {
                loadFraudAlerts() // Refresh alerts
                postSideEffect(
                    AntiMaskingSideEffect.ShowMessage("Alert acknowledged")
                )
            }
    }

    // =========================================================================
    // Real-time Updates
    // =========================================================================

    private fun observeRealTimeUpdates() {
        // Observe new verifications
        repository.observeVerifications()
            .flowOn(ioDispatcher)
            .onEach { verification ->
                intent {
                    reduce {
                        state.copy(
                            verificationHistory = listOf(verification) + state.verificationHistory.take(19)
                        )
                    }

                    if (verification.maskingDetected) {
                        postSideEffect(AntiMaskingSideEffect.TriggerHapticFeedback)
                        postSideEffect(AntiMaskingSideEffect.ShowMaskingAlert(verification))
                    }
                }
            }
            .catch { /* Handle error silently or log */ }
            .launchIn(viewModelScope)

        // Observe fraud alerts
        repository.observeFraudAlerts()
            .flowOn(ioDispatcher)
            .onEach { alert ->
                intent {
                    reduce {
                        state.copy(
                            fraudAlerts = listOf(alert) + state.fraudAlerts,
                            unacknowledgedAlertCount = state.unacknowledgedAlertCount + 1
                        )
                    }
                    postSideEffect(AntiMaskingSideEffect.TriggerHapticFeedback)
                    postSideEffect(AntiMaskingSideEffect.ShowFraudAlert(alert))
                }
            }
            .catch { /* Handle error silently or log */ }
            .launchIn(viewModelScope)
    }

    // =========================================================================
    // Navigation
    // =========================================================================

    fun onVerificationClicked(verificationId: String) = intent {
        postSideEffect(
            AntiMaskingSideEffect.NavigateToVerificationDetails(verificationId)
        )
    }

    // =========================================================================
    // Error Handling
    // =========================================================================

    fun clearError() = intent {
        reduce { state.copy(error = null) }
    }
}
