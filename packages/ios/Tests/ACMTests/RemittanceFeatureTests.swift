import ComposableArchitecture
import Foundation
import XCTest

@testable import ACMPresentation

final class RemittanceFeatureTests: XCTestCase {
    
    @MainActor
    func testAmountChanged_UpdatesStateAndFetchesRate() async {
        let mockRate = ExchangeRate(
            sourceCurrency: .usd,
            targetCurrency: .ngn,
            rate: 1580,
            inverseRate: 0.000633
        )
        
        let store = TestStore(initialState: RemittanceFeature.State()) {
            RemittanceFeature()
        } withDependencies: {
            $0.remittanceClient.getExchangeRate = { _, _ in mockRate }
            $0.hapticClient = .testValue
        }
        
        await store.send(.amountChanged("100")) {
            $0.amountString = "100"
            $0.error = nil
        }
        
        await store.receive(\.fetchExchangeRate) {
            $0.isLoadingRate = true
        }
        
        await store.receive(\.exchangeRateResponse.success) {
            $0.isLoadingRate = false
            $0.exchangeRate = mockRate
        }
    }
    
    @MainActor
    func testReceivedAmount_CalculatesCorrectly() async {
        var state = RemittanceFeature.State()
        state.amountString = "100"
        state.exchangeRate = ExchangeRate(
            sourceCurrency: .usd,
            targetCurrency: .ngn,
            rate: 1580,
            inverseRate: 0.000633
        )
        
        XCTAssertEqual(state.receivedAmount, 158000)
    }
    
    @MainActor
    func testFee_CalculatesCorrectly() async {
        var state = RemittanceFeature.State()
        state.amountString = "100"
        
        // Fee = 1.5% + $2.99 = $1.50 + $2.99 = $4.49
        XCTAssertEqual(state.fee, 4.49)
    }
    
    @MainActor
    func testTotalCost_CalculatesCorrectly() async {
        var state = RemittanceFeature.State()
        state.amountString = "100"
        
        // Total = $100 + $4.49 = $104.49
        XCTAssertEqual(state.totalCost, 104.49)
    }
    
    @MainActor
    func testCanSend_RequiresRecipientAndAmount() async {
        var state = RemittanceFeature.State()
        
        // Can't send without recipient or amount
        XCTAssertFalse(state.canSend)
        
        // Add amount but no recipient
        state.amountString = "100"
        XCTAssertFalse(state.canSend)
        
        // Add recipient
        state.selectedRecipient = Recipient(
            id: .init(rawValue: UUID()),
            fullName: "Test User",
            phoneNumber: "+2348030000000"
        )
        XCTAssertTrue(state.canSend)
        
        // Amount too low
        state.amountString = "5"
        XCTAssertFalse(state.canSend)
    }
    
    @MainActor
    func testSendMoney_Success_UpdatesState() async {
        let mockTransaction = RemittanceTransaction(
            id: .init(rawValue: UUID()),
            senderId: "current-user",
            recipientId: .init(rawValue: UUID()),
            recipientName: "Test User",
            amountSent: 100,
            currencySent: .usd,
            amountReceived: 158000,
            currencyReceived: .ngn,
            exchangeRate: 1580,
            fee: 4.49,
            status: .processing,
            reference: "ACM123456"
        )
        
        var hapticSuccess = false
        
        let store = TestStore(initialState: {
            var state = RemittanceFeature.State()
            state.amountString = "100"
            state.selectedRecipient = Recipient(
                id: .init(rawValue: UUID()),
                fullName: "Test User",
                phoneNumber: "+2348030000000"
            )
            return state
        }()) {
            RemittanceFeature()
        } withDependencies: {
            $0.remittanceClient.initiateRemittance = { _, _, _, _ in mockTransaction }
            $0.remittanceClient.getTransactions = { _, _, _ in [mockTransaction] }
            $0.hapticClient.success = { hapticSuccess = true }
        }
        
        await store.send(.sendMoney) {
            $0.isSending = true
        }
        
        await store.receive(\.sendResponse.success) {
            $0.isSending = false
            $0.lastTransaction = mockTransaction
            $0.amountString = ""
            $0.selectedRecipient = nil
        }
        
        await store.receive(\.loadTransactions) {
            $0.isLoadingTransactions = true
        }
        
        await store.receive(\.transactionsResponse.success) {
            $0.isLoadingTransactions = false
            $0.transactions = [mockTransaction]
        }
        
        XCTAssertTrue(hapticSuccess)
    }
    
    @MainActor
    func testSendMoney_Failure_SetsError() async {
        struct TestError: Error, LocalizedError {
            var errorDescription: String? { "Payment failed" }
        }
        
        var hapticError = false
        
        let store = TestStore(initialState: {
            var state = RemittanceFeature.State()
            state.amountString = "100"
            state.selectedRecipient = Recipient(
                id: .init(rawValue: UUID()),
                fullName: "Test User",
                phoneNumber: "+2348030000000"
            )
            return state
        }()) {
            RemittanceFeature()
        } withDependencies: {
            $0.remittanceClient.initiateRemittance = { _, _, _, _ in throw TestError() }
            $0.hapticClient.error = { hapticError = true }
        }
        
        await store.send(.sendMoney) {
            $0.isSending = true
        }
        
        await store.receive(\.sendResponse.failure) {
            $0.isSending = false
            $0.error = "Payment failed"
        }
        
        XCTAssertTrue(hapticError)
    }
    
    @MainActor
    func testLoadRecipients_PopulatesList() async {
        let mockRecipients = [
            Recipient(
                id: .init(rawValue: UUID()),
                fullName: "Chidi Okafor",
                phoneNumber: "+2348030123456",
                bankName: "GTBank",
                isFavorite: true
            ),
            Recipient(
                id: .init(rawValue: UUID()),
                fullName: "Amina Ibrahim",
                phoneNumber: "+2348060789012",
                bankName: "Access Bank"
            )
        ]
        
        let store = TestStore(initialState: RemittanceFeature.State()) {
            RemittanceFeature()
        } withDependencies: {
            $0.remittanceClient.getRecipients = { mockRecipients }
            $0.hapticClient = .testValue
        }
        
        await store.send(.loadRecipients) {
            $0.isLoadingRecipients = true
        }
        
        await store.receive(\.recipientsResponse.success) {
            $0.isLoadingRecipients = false
            $0.recipients = IdentifiedArray(uniqueElements: mockRecipients)
        }
    }
    
    @MainActor
    func testSourceCurrencySelected_UpdatesAndFetchesRate() async {
        let mockRate = ExchangeRate(
            sourceCurrency: .gbp,
            targetCurrency: .ngn,
            rate: 2000,
            inverseRate: 0.0005
        )
        
        let store = TestStore(initialState: RemittanceFeature.State()) {
            RemittanceFeature()
        } withDependencies: {
            $0.remittanceClient.getExchangeRate = { _, _ in mockRate }
            $0.hapticClient = .testValue
        }
        
        await store.send(.sourceCurrencySelected(.gbp)) {
            $0.sourceCurrency = .gbp
        }
        
        await store.receive(\.fetchExchangeRate) {
            $0.isLoadingRate = true
        }
        
        await store.receive(\.exchangeRateResponse.success) {
            $0.isLoadingRate = false
            $0.exchangeRate = mockRate
        }
    }
}
