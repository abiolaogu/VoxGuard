import ComposableArchitecture
import Foundation

// MARK: - Remittance Feature Reducer

@Reducer
public struct RemittanceFeature {
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        // Send money form
        public var selectedRecipient: Recipient?
        public var amountString: String = ""
        public var sourceCurrency: Currency = .usd
        public var targetCurrency: Currency = .ngn
        
        // Exchange rate
        public var exchangeRate: ExchangeRate?
        public var isLoadingRate: Bool = false
        
        // Recipients
        public var recipients: IdentifiedArrayOf<Recipient> = []
        public var isLoadingRecipients: Bool = false
        
        // Transactions
        public var transactions: IdentifiedArrayOf<RemittanceTransaction> = []
        public var isLoadingTransactions: Bool = false
        
        // Processing
        public var isSending: Bool = false
        public var lastTransaction: RemittanceTransaction?
        
        // Error
        public var error: String?
        
        // Computed
        public var amount: Decimal? {
            Decimal(string: amountString)
        }
        
        public var receivedAmount: Decimal? {
            guard let amount = amount, let rate = exchangeRate else { return nil }
            return amount * rate.rate
        }
        
        public var fee: Decimal {
            guard let amount = amount else { return 0 }
            return (amount * Decimal(0.015)) + Decimal(2.99)
        }
        
        public var totalCost: Decimal? {
            guard let amount = amount else { return nil }
            return amount + fee
        }
        
        public var canSend: Bool {
            selectedRecipient != nil &&
            amount != nil &&
            (amount ?? 0) >= 10 &&
            !isSending
        }
        
        public init() {}
    }
    
    // MARK: - Action
    
    public enum Action: Equatable {
        // Form actions
        case amountChanged(String)
        case sourceCurrencySelected(Currency)
        case targetCurrencySelected(Currency)
        case recipientSelected(Recipient)
        
        // Exchange rate
        case fetchExchangeRate
        case exchangeRateResponse(Result<ExchangeRate, Error>)
        
        // Recipients
        case loadRecipients
        case recipientsResponse(Result<[Recipient], Error>)
        case addRecipient
        case deleteRecipient(RecipientID)
        
        // Transaction
        case sendMoney
        case sendResponse(Result<RemittanceTransaction, Error>)
        case loadTransactions
        case transactionsResponse(Result<[RemittanceTransaction], Error>)
        
        // Error
        case clearError
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.remittanceClient) var client
    @Dependency(\.hapticClient) var haptics
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                
            // MARK: Form Actions
                
            case let .amountChanged(amount):
                state.amountString = amount
                state.error = nil
                return .send(.fetchExchangeRate)
                
            case let .sourceCurrencySelected(currency):
                state.sourceCurrency = currency
                return .send(.fetchExchangeRate)
                
            case let .targetCurrencySelected(currency):
                state.targetCurrency = currency
                return .send(.fetchExchangeRate)
                
            case let .recipientSelected(recipient):
                state.selectedRecipient = recipient
                return .none
                
            // MARK: Exchange Rate
                
            case .fetchExchangeRate:
                state.isLoadingRate = true
                let source = state.sourceCurrency
                let target = state.targetCurrency
                
                return .run { send in
                    await send(.exchangeRateResponse(
                        Result { try await client.getExchangeRate(source, target) }
                    ))
                }
                
            case let .exchangeRateResponse(.success(rate)):
                state.isLoadingRate = false
                state.exchangeRate = rate
                return .none
                
            case let .exchangeRateResponse(.failure(error)):
                state.isLoadingRate = false
                state.error = error.localizedDescription
                return .none
                
            // MARK: Recipients
                
            case .loadRecipients:
                state.isLoadingRecipients = true
                
                return .run { send in
                    await send(.recipientsResponse(
                        Result { try await client.getRecipients() }
                    ))
                }
                
            case let .recipientsResponse(.success(recipients)):
                state.isLoadingRecipients = false
                state.recipients = IdentifiedArray(uniqueElements: recipients)
                return .none
                
            case let .recipientsResponse(.failure(error)):
                state.isLoadingRecipients = false
                state.error = error.localizedDescription
                return .none
                
            case .addRecipient:
                // Navigate to add recipient
                return .none
                
            case let .deleteRecipient(id):
                state.recipients.remove(id: id)
                return .run { _ in
                    try await client.deleteRecipient(id.rawValue.uuidString)
                }
                
            // MARK: Transaction
                
            case .sendMoney:
                guard state.canSend,
                      let recipient = state.selectedRecipient,
                      let amount = state.amount else { return .none }
                
                state.isSending = true
                
                let source = state.sourceCurrency
                let target = state.targetCurrency
                
                return .run { send in
                    await send(.sendResponse(
                        Result {
                            try await client.initiateRemittance(
                                recipient.id.rawValue.uuidString,
                                amount,
                                source,
                                target
                            )
                        }
                    ))
                }
                
            case let .sendResponse(.success(transaction)):
                state.isSending = false
                state.lastTransaction = transaction
                state.amountString = ""
                state.selectedRecipient = nil
                
                return .merge(
                    .run { _ in await haptics.success() },
                    .send(.loadTransactions)
                )
                
            case let .sendResponse(.failure(error)):
                state.isSending = false
                state.error = error.localizedDescription
                return .run { _ in await haptics.error() }
                
            case .loadTransactions:
                state.isLoadingTransactions = true
                
                return .run { send in
                    await send(.transactionsResponse(
                        Result { try await client.getTransactions(20, 0, nil) }
                    ))
                }
                
            case let .transactionsResponse(.success(transactions)):
                state.isLoadingTransactions = false
                state.transactions = IdentifiedArray(uniqueElements: transactions)
                return .none
                
            case let .transactionsResponse(.failure(error)):
                state.isLoadingTransactions = false
                state.error = error.localizedDescription
                return .none
                
            // MARK: Error
                
            case .clearError:
                state.error = nil
                return .none
            }
        }
    }
    
    public init() {}
}
