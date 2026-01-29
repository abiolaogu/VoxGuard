package com.billyrinks.antimasking.presentation.anti_masking

import com.billyrinks.antimasking.domain.model.*
import com.billyrinks.antimasking.domain.repository.AntiMaskingRepository
import com.billyrinks.antimasking.domain.usecase.GetVerificationHistoryUseCase
import com.billyrinks.antimasking.domain.usecase.ReportMaskingUseCase
import com.billyrinks.antimasking.domain.usecase.VerifyCallUseCase
import io.mockk.coEvery
import io.mockk.mockk
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.orbitmvi.orbit.test.test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

@OptIn(ExperimentalCoroutinesApi::class)
class AntiMaskingViewModelTest {

    private val testDispatcher = StandardTestDispatcher()

    private lateinit var verifyCallUseCase: VerifyCallUseCase
    private lateinit var getVerificationHistoryUseCase: GetVerificationHistoryUseCase
    private lateinit var reportMaskingUseCase: ReportMaskingUseCase
    private lateinit var repository: AntiMaskingRepository

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)

        repository = mockk {
            coEvery { getFraudAlerts(any(), any()) } returns Result.success(emptyList())
            coEvery { observeVerifications() } returns emptyFlow()
            coEvery { observeFraudAlerts() } returns emptyFlow()
        }

        verifyCallUseCase = mockk()
        getVerificationHistoryUseCase = mockk()
        reportMaskingUseCase = mockk()
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    private fun createViewModel(): AntiMaskingViewModel {
        return AntiMaskingViewModel(
            verifyCallUseCase = verifyCallUseCase,
            getVerificationHistoryUseCase = getVerificationHistoryUseCase,
            reportMaskingUseCase = reportMaskingUseCase,
            repository = repository,
            ioDispatcher = testDispatcher
        )
    }

    @Test
    fun `initial state should be correct`() = runTest {
        coEvery { getVerificationHistoryUseCase(any(), any(), any()) } returns Result.success(emptyList())

        val viewModel = createViewModel()

        viewModel.test(this) {
            val initialState = expectInitialState()
            assertEquals("", initialState.callerNumber)
            assertEquals("", initialState.calleeNumber)
            assertFalse(initialState.isVerifying)
            assertFalse(initialState.canVerify)
        }
    }

    @Test
    fun `onCallerNumberChanged updates state with MNO detection`() = runTest {
        coEvery { getVerificationHistoryUseCase(any(), any(), any()) } returns Result.success(emptyList())

        val viewModel = createViewModel()

        viewModel.test(this) {
            expectInitialState()

            viewModel.onCallerNumberChanged("08030001234")

            val state = expectState()
            assertEquals("08030001234", state.callerNumber)
            assertEquals(NigerianMno.MTN, state.callerMno)
        }
    }

    @Test
    fun `canVerify is true when both numbers are valid`() = runTest {
        coEvery { getVerificationHistoryUseCase(any(), any(), any()) } returns Result.success(emptyList())

        val viewModel = createViewModel()

        viewModel.test(this) {
            expectInitialState()

            viewModel.onCallerNumberChanged("08030001234")
            expectState()

            viewModel.onCalleeNumberChanged("09010005678")
            val state = expectState()

            assertTrue(state.canVerify)
        }
    }

    @Test
    fun `verifyCall success updates state with verification`() = runTest {
        val mockVerification = CallVerification(
            id = "test-id",
            callerNumber = "+2348030001234",
            calleeNumber = "+2349010005678",
            originalCli = "+2348030001234",
            detectedCli = null,
            maskingDetected = false,
            confidenceScore = 0.2,
            status = VerificationStatus.VERIFIED,
            gatewayName = "GTW-Lagos-001",
            detectedMno = "MTN",
            verifiedAt = Instant.now(),
            createdAt = Instant.now()
        )

        coEvery { getVerificationHistoryUseCase(any(), any(), any()) } returns Result.success(emptyList())
        coEvery { verifyCallUseCase(any(), any()) } returns Result.success(mockVerification)

        val viewModel = createViewModel()

        viewModel.test(this) {
            expectInitialState()

            viewModel.onCallerNumberChanged("08030001234")
            expectState()

            viewModel.onCalleeNumberChanged("09010005678")
            expectState()

            viewModel.verifyCall()

            // Expect loading state
            val loadingState = expectState()
            assertTrue(loadingState.isVerifying)

            // Expect success state
            val successState = expectState()
            assertFalse(successState.isVerifying)
            assertEquals(mockVerification, successState.latestVerification)

            // Expect success message side effect
            expectSideEffect()
        }
    }

    @Test
    fun `verifyCall with masking triggers alert side effects`() = runTest {
        val mockVerification = CallVerification(
            id = "test-id",
            callerNumber = "+2348030001234",
            calleeNumber = "+2349010005678",
            originalCli = "+2348030001234",
            detectedCli = "+2348099999999",
            maskingDetected = true,
            confidenceScore = 0.85,
            status = VerificationStatus.MASKING_DETECTED,
            gatewayName = "GTW-Lagos-001",
            detectedMno = "MTN",
            verifiedAt = Instant.now(),
            createdAt = Instant.now()
        )

        coEvery { getVerificationHistoryUseCase(any(), any(), any()) } returns Result.success(emptyList())
        coEvery { verifyCallUseCase(any(), any()) } returns Result.success(mockVerification)

        val viewModel = createViewModel()

        viewModel.test(this) {
            expectInitialState()

            viewModel.onCallerNumberChanged("08030001234")
            expectState()

            viewModel.onCalleeNumberChanged("09010005678")
            expectState()

            viewModel.verifyCall()

            expectState() // loading
            expectState() // success

            // Expect haptic, sound, and alert side effects
            val hapticEffect = expectSideEffect()
            assertTrue(hapticEffect is AntiMaskingSideEffect.TriggerHapticFeedback)

            val soundEffect = expectSideEffect()
            assertTrue(soundEffect is AntiMaskingSideEffect.PlayMaskingAlertSound)

            val alertEffect = expectSideEffect()
            assertTrue(alertEffect is AntiMaskingSideEffect.ShowMaskingAlert)
        }
    }

    @Test
    fun `verifyCall failure shows error message`() = runTest {
        coEvery { getVerificationHistoryUseCase(any(), any(), any()) } returns Result.success(emptyList())
        coEvery { verifyCallUseCase(any(), any()) } returns Result.failure(Exception("Network error"))

        val viewModel = createViewModel()

        viewModel.test(this) {
            expectInitialState()

            viewModel.onCallerNumberChanged("08030001234")
            expectState()

            viewModel.onCalleeNumberChanged("09010005678")
            expectState()

            viewModel.verifyCall()

            expectState() // loading

            val errorState = expectState()
            assertFalse(errorState.isVerifying)
            assertEquals("Network error", errorState.error)

            val errorEffect = expectSideEffect()
            assertTrue(errorEffect is AntiMaskingSideEffect.ShowMessage)
            assertTrue((errorEffect as AntiMaskingSideEffect.ShowMessage).isError)
        }
    }

    @Test
    fun `reportToNCC success shows confirmation`() = runTest {
        coEvery { getVerificationHistoryUseCase(any(), any(), any()) } returns Result.success(emptyList())
        coEvery { reportMaskingUseCase(any(), any()) } returns Result.success(Unit)

        val viewModel = createViewModel()

        viewModel.test(this) {
            expectInitialState()

            viewModel.reportToNCC("test-verification-id")

            expectState() // loading

            val successState = expectState()
            assertFalse(successState.isLoading)

            val reportEffect = expectSideEffect()
            assertTrue(reportEffect is AntiMaskingSideEffect.ReportSubmittedSuccessfully)

            val messageEffect = expectSideEffect()
            assertTrue(messageEffect is AntiMaskingSideEffect.ShowMessage)
        }
    }

    @Test
    fun `toggleMaskingFilter updates filter state`() = runTest {
        coEvery { getVerificationHistoryUseCase(any(), any(), any()) } returns Result.success(emptyList())

        val viewModel = createViewModel()

        viewModel.test(this) {
            val initialState = expectInitialState()
            assertFalse(initialState.showMaskingDetectedOnly)

            viewModel.toggleMaskingFilter()

            val toggledState = expectState()
            assertTrue(toggledState.showMaskingDetectedOnly)
        }
    }

    @Test
    fun `NigerianMno correctly detects MTN prefixes`() {
        val mtnNumbers = listOf(
            "08030001234",
            "08060001234",
            "07030001234",
            "09030001234",
            "+2348030001234"
        )

        mtnNumbers.forEach { number ->
            assertEquals(
                NigerianMno.MTN,
                NigerianMno.fromPhoneNumber(number),
                "Failed for number: $number"
            )
        }
    }

    @Test
    fun `NigerianMno correctly detects Glo prefixes`() {
        val gloNumbers = listOf(
            "08050001234",
            "08150001234",
            "07050001234"
        )

        gloNumbers.forEach { number ->
            assertEquals(
                NigerianMno.GLO,
                NigerianMno.fromPhoneNumber(number),
                "Failed for number: $number"
            )
        }
    }

    @Test
    fun `NigerianMno returns UNKNOWN for invalid numbers`() {
        val invalidNumbers = listOf(
            "12345",
            "",
            "abcdefghijk"
        )

        invalidNumbers.forEach { number ->
            assertEquals(
                NigerianMno.UNKNOWN,
                NigerianMno.fromPhoneNumber(number),
                "Failed for number: $number"
            )
        }
    }
}
