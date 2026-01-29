package com.billyrinks.antimasking.domain.repository

import com.billyrinks.antimasking.domain.model.*
import kotlinx.coroutines.flow.Flow
import java.math.BigDecimal

/**
 * Repository interface for remittance operations
 */
interface RemittanceRepository {

    /**
     * Get exchange rate for a currency pair
     */
    suspend fun getExchangeRate(
        sourceCurrency: Currency,
        targetCurrency: Currency
    ): Result<ExchangeRate>

    /**
     * Get available corridors for remittance
     */
    suspend fun getCorridors(): Result<List<Corridor>>

    /**
     * Initiate a new remittance transaction
     */
    suspend fun initiateRemittance(
        recipientId: String,
        amountSent: BigDecimal,
        sourceCurrency: Currency,
        targetCurrency: Currency
    ): Result<RemittanceTransaction>

    /**
     * Get transaction by ID
     */
    suspend fun getTransaction(id: String): Result<RemittanceTransaction>

    /**
     * Get transaction history
     */
    suspend fun getTransactions(
        limit: Int = 20,
        offset: Int = 0,
        status: TransactionStatus? = null
    ): Result<List<RemittanceTransaction>>

    /**
     * Subscribe to transaction status updates
     */
    fun observeTransactionStatus(transactionId: String): Flow<RemittanceTransaction>

    /**
     * Get recipients list
     */
    suspend fun getRecipients(): Result<List<Recipient>>

    /**
     * Add a new recipient
     */
    suspend fun addRecipient(
        fullName: String,
        phoneNumber: String,
        bankCode: String?,
        accountNumber: String?,
        state: String?
    ): Result<Recipient>

    /**
     * Delete a recipient
     */
    suspend fun deleteRecipient(recipientId: String): Result<Unit>
}
