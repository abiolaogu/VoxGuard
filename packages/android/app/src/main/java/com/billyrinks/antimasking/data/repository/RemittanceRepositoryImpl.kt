package com.billyrinks.antimasking.data.repository

import com.apollographql.apollo3.ApolloClient
import com.billyrinks.antimasking.di.IoDispatcher
import com.billyrinks.antimasking.domain.model.*
import com.billyrinks.antimasking.domain.repository.RemittanceRepository
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.withContext
import java.math.BigDecimal
import java.time.Instant
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Implementation of RemittanceRepository
 */
@Singleton
class RemittanceRepositoryImpl @Inject constructor(
    private val apolloClient: ApolloClient,
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher
) : RemittanceRepository {

    override suspend fun getExchangeRate(
        sourceCurrency: Currency,
        targetCurrency: Currency
    ): Result<ExchangeRate> = withContext(ioDispatcher) {
        try {
            delay(500)
            
            val rate = when {
                sourceCurrency == Currency.USD && targetCurrency == Currency.NGN -> BigDecimal("1580.00")
                sourceCurrency == Currency.GBP && targetCurrency == Currency.NGN -> BigDecimal("2000.00")
                sourceCurrency == Currency.EUR && targetCurrency == Currency.NGN -> BigDecimal("1720.00")
                sourceCurrency == Currency.CAD && targetCurrency == Currency.NGN -> BigDecimal("1170.00")
                else -> BigDecimal("1580.00")
            }

            Result.success(
                ExchangeRate(
                    sourceCurrency = sourceCurrency,
                    targetCurrency = targetCurrency,
                    rate = rate,
                    inverseRate = BigDecimal.ONE.divide(rate, 8, java.math.RoundingMode.HALF_UP),
                    timestamp = Instant.now()
                )
            )
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getCorridors(): Result<List<Corridor>> = withContext(ioDispatcher) {
        try {
            Result.success(
                listOf(
                    Corridor(
                        id = "usd-ngn",
                        sourceCurrency = Currency.USD,
                        targetCurrency = Currency.NGN,
                        minAmount = BigDecimal("10"),
                        maxAmount = BigDecimal("10000"),
                        feePercentage = BigDecimal("1.5"),
                        flatFee = BigDecimal("2.99"),
                        isActive = true
                    ),
                    Corridor(
                        id = "gbp-ngn",
                        sourceCurrency = Currency.GBP,
                        targetCurrency = Currency.NGN,
                        minAmount = BigDecimal("10"),
                        maxAmount = BigDecimal("8000"),
                        feePercentage = BigDecimal("1.5"),
                        flatFee = BigDecimal("2.49"),
                        isActive = true
                    ),
                    Corridor(
                        id = "eur-ngn",
                        sourceCurrency = Currency.EUR,
                        targetCurrency = Currency.NGN,
                        minAmount = BigDecimal("10"),
                        maxAmount = BigDecimal("9000"),
                        feePercentage = BigDecimal("1.5"),
                        flatFee = BigDecimal("2.49"),
                        isActive = true
                    )
                )
            )
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun initiateRemittance(
        recipientId: String,
        amountSent: BigDecimal,
        sourceCurrency: Currency,
        targetCurrency: Currency
    ): Result<RemittanceTransaction> = withContext(ioDispatcher) {
        try {
            delay(2000) // Simulate processing
            
            val rate = BigDecimal("1580.00")
            val fee = amountSent.multiply(BigDecimal("0.015")) + BigDecimal("2.99")
            
            Result.success(
                RemittanceTransaction(
                    id = UUID.randomUUID().toString(),
                    senderId = "current-user",
                    recipientId = recipientId,
                    recipientName = "John Doe",
                    amountSent = amountSent,
                    currencySent = sourceCurrency,
                    amountReceived = amountSent.multiply(rate),
                    currencyReceived = targetCurrency,
                    exchangeRate = rate,
                    fee = fee,
                    status = TransactionStatus.PROCESSING,
                    reference = "ACM${System.currentTimeMillis()}",
                    createdAt = Instant.now()
                )
            )
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getTransaction(id: String): Result<RemittanceTransaction> =
        withContext(ioDispatcher) {
            try {
                delay(300)
                Result.success(
                    RemittanceTransaction(
                        id = id,
                        senderId = "current-user",
                        recipientId = "recipient-1",
                        recipientName = "John Doe",
                        amountSent = BigDecimal("100"),
                        currencySent = Currency.USD,
                        amountReceived = BigDecimal("158000"),
                        currencyReceived = Currency.NGN,
                        exchangeRate = BigDecimal("1580.00"),
                        fee = BigDecimal("4.49"),
                        status = TransactionStatus.COMPLETED,
                        reference = "ACM123456",
                        createdAt = Instant.now().minusSeconds(3600),
                        completedAt = Instant.now()
                    )
                )
            } catch (e: Exception) {
                Result.failure(e)
            }
        }

    override suspend fun getTransactions(
        limit: Int,
        offset: Int,
        status: TransactionStatus?
    ): Result<List<RemittanceTransaction>> = withContext(ioDispatcher) {
        try {
            delay(500)
            
            val transactions = (1..limit).map { index ->
                RemittanceTransaction(
                    id = UUID.randomUUID().toString(),
                    senderId = "current-user",
                    recipientId = "recipient-$index",
                    recipientName = listOf("Chidi Okafor", "Amina Ibrahim", "Femi Adeyemi").random(),
                    amountSent = BigDecimal((50..500).random()),
                    currencySent = Currency.USD,
                    amountReceived = BigDecimal((79000..790000).random()),
                    currencyReceived = Currency.NGN,
                    exchangeRate = BigDecimal("1580.00"),
                    fee = BigDecimal("4.49"),
                    status = TransactionStatus.entries.random(),
                    reference = "ACM${System.currentTimeMillis()}$index",
                    createdAt = Instant.now().minusSeconds((index * 86400).toLong())
                )
            }
            
            Result.success(transactions)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override fun observeTransactionStatus(transactionId: String): Flow<RemittanceTransaction> = flow {
        // Simulate status updates
        val statuses = listOf(
            TransactionStatus.PENDING,
            TransactionStatus.PROCESSING,
            TransactionStatus.COMPLETED
        )
        
        for (status in statuses) {
            delay(3000)
            emit(
                RemittanceTransaction(
                    id = transactionId,
                    senderId = "current-user",
                    recipientId = "recipient-1",
                    recipientName = "John Doe",
                    amountSent = BigDecimal("100"),
                    currencySent = Currency.USD,
                    amountReceived = BigDecimal("158000"),
                    currencyReceived = Currency.NGN,
                    exchangeRate = BigDecimal("1580.00"),
                    fee = BigDecimal("4.49"),
                    status = status,
                    reference = "ACM123456",
                    createdAt = Instant.now().minusSeconds(300)
                )
            )
        }
    }.flowOn(ioDispatcher)

    override suspend fun getRecipients(): Result<List<Recipient>> = withContext(ioDispatcher) {
        try {
            delay(400)
            
            Result.success(
                listOf(
                    Recipient(
                        id = "1",
                        fullName = "Chidi Okafor",
                        phoneNumber = "+2348030123456",
                        bankName = "GTBank",
                        bankCode = "058",
                        accountNumber = "0123456789",
                        state = "Lagos",
                        isFavorite = true,
                        createdAt = Instant.now().minusSeconds(86400 * 30)
                    ),
                    Recipient(
                        id = "2",
                        fullName = "Amina Ibrahim",
                        phoneNumber = "+2348060789012",
                        bankName = "Access Bank",
                        bankCode = "044",
                        accountNumber = "9876543210",
                        state = "Abuja",
                        isFavorite = false,
                        createdAt = Instant.now().minusSeconds(86400 * 7)
                    )
                )
            )
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun addRecipient(
        fullName: String,
        phoneNumber: String,
        bankCode: String?,
        accountNumber: String?,
        state: String?
    ): Result<Recipient> = withContext(ioDispatcher) {
        try {
            delay(1000)
            
            Result.success(
                Recipient(
                    id = UUID.randomUUID().toString(),
                    fullName = fullName,
                    phoneNumber = phoneNumber,
                    bankName = bankCode?.let { NigerianBank.allBanks.find { b -> b.code == it }?.name },
                    bankCode = bankCode,
                    accountNumber = accountNumber,
                    state = state,
                    isFavorite = false,
                    createdAt = Instant.now()
                )
            )
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun deleteRecipient(recipientId: String): Result<Unit> =
        withContext(ioDispatcher) {
            try {
                delay(500)
                Result.success(Unit)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
}
