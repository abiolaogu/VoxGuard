package com.acm.android.features.fraud.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.acm.android.features.fraud.ui.FraudDashboardUiState
import com.acm.android.features.fraud.ui.FraudSummaryState
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * Fraud Summary Data
 */
data class FraudSummary(
    val cliSpoofingCount: Int = 0,
    val irsfCount: Int = 0,
    val wangiriCount: Int = 0,
    val callbackFraudCount: Int = 0,
    val totalRevenueProtected: Double = 0.0
)

/**
 * Fraud Dashboard ViewModel
 */
@HiltViewModel
class FraudDashboardViewModel @Inject constructor(
    private val fraudRepository: FraudRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(FraudDashboardUiState())
    val uiState: StateFlow<FraudDashboardUiState> = _uiState.asStateFlow()

    init {
        loadFraudSummary()
    }

    fun refresh() {
        loadFraudSummary()
    }

    private fun loadFraudSummary() {
        viewModelScope.launch {
            _uiState.update { it.copy(summary = FraudSummaryState.Loading) }
            
            try {
                val summary = fraudRepository.getFraudSummary()
                _uiState.update { it.copy(summary = FraudSummaryState.Success(summary)) }
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(summary = FraudSummaryState.Error(e.message ?: "Unknown error")) 
                }
            }
        }
    }
}

/**
 * Fraud Repository Interface
 */
interface FraudRepository {
    suspend fun getFraudSummary(): FraudSummary
    suspend fun getCLIVerifications(): List<CLIVerification>
    suspend fun getIRSFIncidents(): List<IRSFIncident>
    suspend fun getWangiriIncidents(): List<WangiriIncident>
    suspend fun blockNumber(number: String, reason: String)
}

// Domain Models
data class CLIVerification(
    val id: String,
    val presentedCli: String,
    val actualCli: String?,
    val spoofingDetected: Boolean,
    val spoofingType: String?,
    val confidenceScore: Double?
)

data class IRSFIncident(
    val id: String,
    val sourceNumber: String,
    val destinationNumber: String,
    val destinationCountry: String,
    val riskScore: Double,
    val estimatedLoss: Double?
)

data class WangiriIncident(
    val id: String,
    val sourceNumber: String,
    val targetNumber: String,
    val ringDurationMs: Int,
    val confidenceScore: Double,
    val callbackBlocked: Boolean
)
