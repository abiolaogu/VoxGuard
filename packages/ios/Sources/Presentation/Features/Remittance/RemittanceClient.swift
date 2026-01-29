import Dependencies
import Foundation

// MARK: - Remittance Client Dependency

public struct RemittanceClient: Sendable {
    public var getExchangeRate: @Sendable (Currency, Currency) async throws -> ExchangeRate
    public var getCorridors: @Sendable () async throws -> [Corridor]
    public var initiateRemittance: @Sendable (String, Decimal, Currency, Currency) async throws -> RemittanceTransaction
    public var getTransaction: @Sendable (String) async throws -> RemittanceTransaction
    public var getTransactions: @Sendable (Int, Int, TransactionStatus?) async throws -> [RemittanceTransaction]
    public var getRecipients: @Sendable () async throws -> [Recipient]
    public var addRecipient: @Sendable (String, String, String?, String?, String?) async throws -> Recipient
    public var deleteRecipient: @Sendable (String) async throws -> Void
    
    public init(
        getExchangeRate: @escaping @Sendable (Currency, Currency) async throws -> ExchangeRate,
        getCorridors: @escaping @Sendable () async throws -> [Corridor],
        initiateRemittance: @escaping @Sendable (String, Decimal, Currency, Currency) async throws -> RemittanceTransaction,
        getTransaction: @escaping @Sendable (String) async throws -> RemittanceTransaction,
        getTransactions: @escaping @Sendable (Int, Int, TransactionStatus?) async throws -> [RemittanceTransaction],
        getRecipients: @escaping @Sendable () async throws -> [Recipient],
        addRecipient: @escaping @Sendable (String, String, String?, String?, String?) async throws -> Recipient,
        deleteRecipient: @escaping @Sendable (String) async throws -> Void
    ) {
        self.getExchangeRate = getExchangeRate
        self.getCorridors = getCorridors
        self.initiateRemittance = initiateRemittance
        self.getTransaction = getTransaction
        self.getTransactions = getTransactions
        self.getRecipients = getRecipients
        self.addRecipient = addRecipient
        self.deleteRecipient = deleteRecipient
    }
}

// MARK: - Corridor

public struct Corridor: Equatable, Identifiable, Sendable {
    public let id: String
    public let sourceCurrency: Currency
    public let targetCurrency: Currency
    public let minAmount: Decimal
    public let maxAmount: Decimal
    public let feePercentage: Decimal
    public let flatFee: Decimal
    public let isActive: Bool
    
    public init(
        id: String,
        sourceCurrency: Currency,
        targetCurrency: Currency,
        minAmount: Decimal,
        maxAmount: Decimal,
        feePercentage: Decimal,
        flatFee: Decimal,
        isActive: Bool = true
    ) {
        self.id = id
        self.sourceCurrency = sourceCurrency
        self.targetCurrency = targetCurrency
        self.minAmount = minAmount
        self.maxAmount = maxAmount
        self.feePercentage = feePercentage
        self.flatFee = flatFee
        self.isActive = isActive
    }
}

// MARK: - Dependency Key

extension RemittanceClient: DependencyKey {
    public static var liveValue: RemittanceClient {
        RemittanceClient(
            getExchangeRate: { source, target in
                try await Task.sleep(nanoseconds: 500_000_000)
                
                let rate: Decimal
                switch (source, target) {
                case (.usd, .ngn): rate = 1580
                case (.gbp, .ngn): rate = 2000
                case (.eur, .ngn): rate = 1720
                case (.cad, .ngn): rate = 1170
                default: rate = 1580
                }
                
                return ExchangeRate(
                    sourceCurrency: source,
                    targetCurrency: target,
                    rate: rate,
                    inverseRate: 1 / rate,
                    timestamp: Date()
                )
            },
            getCorridors: {
                [
                    Corridor(id: "usd-ngn", sourceCurrency: .usd, targetCurrency: .ngn, 
                            minAmount: 10, maxAmount: 10000, feePercentage: 1.5, flatFee: 2.99),
                    Corridor(id: "gbp-ngn", sourceCurrency: .gbp, targetCurrency: .ngn,
                            minAmount: 10, maxAmount: 8000, feePercentage: 1.5, flatFee: 2.49),
                    Corridor(id: "eur-ngn", sourceCurrency: .eur, targetCurrency: .ngn,
                            minAmount: 10, maxAmount: 9000, feePercentage: 1.5, flatFee: 2.49)
                ]
            },
            initiateRemittance: { recipientId, amount, source, target in
                try await Task.sleep(nanoseconds: 2_000_000_000)
                
                return RemittanceTransaction(
                    id: .init(rawValue: UUID()),
                    senderId: "current-user",
                    recipientId: .init(rawValue: UUID(uuidString: recipientId) ?? UUID()),
                    recipientName: "John Doe",
                    amountSent: amount,
                    currencySent: source,
                    amountReceived: amount * 1580,
                    currencyReceived: target,
                    exchangeRate: 1580,
                    fee: (amount * Decimal(0.015)) + Decimal(2.99),
                    status: .processing,
                    reference: "ACM\(Date().timeIntervalSince1970)",
                    createdAt: Date()
                )
            },
            getTransaction: { id in
                try await Task.sleep(nanoseconds: 300_000_000)
                
                return RemittanceTransaction(
                    id: .init(rawValue: UUID(uuidString: id) ?? UUID()),
                    senderId: "current-user",
                    recipientId: .init(rawValue: UUID()),
                    recipientName: "John Doe",
                    amountSent: 100,
                    currencySent: .usd,
                    amountReceived: 158000,
                    currencyReceived: .ngn,
                    exchangeRate: 1580,
                    fee: 4.49,
                    status: .completed,
                    reference: "ACM123456",
                    createdAt: Date().addingTimeInterval(-3600),
                    completedAt: Date()
                )
            },
            getTransactions: { limit, offset, status in
                try await Task.sleep(nanoseconds: 500_000_000)
                
                return (0..<limit).map { index in
                    RemittanceTransaction(
                        id: .init(rawValue: UUID()),
                        senderId: "current-user",
                        recipientId: .init(rawValue: UUID()),
                        recipientName: ["Chidi Okafor", "Amina Ibrahim", "Femi Adeyemi"].randomElement()!,
                        amountSent: Decimal(Int.random(in: 50...500)),
                        currencySent: .usd,
                        amountReceived: Decimal(Int.random(in: 79000...790000)),
                        currencyReceived: .ngn,
                        exchangeRate: 1580,
                        fee: 4.49,
                        status: TransactionStatus.allCases.randomElement()!,
                        reference: "ACM\(Date().timeIntervalSince1970)\(index)",
                        createdAt: Date().addingTimeInterval(TimeInterval(-index * 86400))
                    )
                }
            },
            getRecipients: {
                try await Task.sleep(nanoseconds: 400_000_000)
                
                return [
                    Recipient(
                        id: .init(rawValue: UUID()),
                        fullName: "Chidi Okafor",
                        phoneNumber: "+2348030123456",
                        bankName: "GTBank",
                        bankCode: "058",
                        accountNumber: "0123456789",
                        state: .lagos,
                        isFavorite: true
                    ),
                    Recipient(
                        id: .init(rawValue: UUID()),
                        fullName: "Amina Ibrahim",
                        phoneNumber: "+2348060789012",
                        bankName: "Access Bank",
                        bankCode: "044",
                        accountNumber: "9876543210",
                        state: .fct,
                        isFavorite: false
                    )
                ]
            },
            addRecipient: { name, phone, bankCode, accountNumber, state in
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                return Recipient(
                    id: .init(rawValue: UUID()),
                    fullName: name,
                    phoneNumber: phone,
                    bankName: bankCode.flatMap { code in NigerianBank.allBanks.first { $0.code == code }?.name },
                    bankCode: bankCode,
                    accountNumber: accountNumber,
                    state: state.flatMap { NigerianState(rawValue: $0) }
                )
            },
            deleteRecipient: { _ in
                try await Task.sleep(nanoseconds: 500_000_000)
            }
        )
    }
    
    public static var testValue: RemittanceClient {
        RemittanceClient(
            getExchangeRate: { _, _ in
                ExchangeRate(sourceCurrency: .usd, targetCurrency: .ngn, rate: 1580, inverseRate: 0.000633)
            },
            getCorridors: { [] },
            initiateRemittance: { _, _, _, _ in fatalError() },
            getTransaction: { _ in fatalError() },
            getTransactions: { _, _, _ in [] },
            getRecipients: { [] },
            addRecipient: { _, _, _, _, _ in fatalError() },
            deleteRecipient: { _ in }
        )
    }
}

extension DependencyValues {
    public var remittanceClient: RemittanceClient {
        get { self[RemittanceClient.self] }
        set { self[RemittanceClient.self] = newValue }
    }
}
