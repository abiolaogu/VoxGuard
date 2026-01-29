import Foundation
import Tagged

// MARK: - Remittance Transaction

public typealias TransactionID = Tagged<RemittanceTransaction, UUID>
public typealias RecipientID = Tagged<Recipient, UUID>

public struct RemittanceTransaction: Equatable, Identifiable, Sendable {
    public let id: TransactionID
    public let senderId: String
    public let recipientId: RecipientID
    public let recipientName: String
    public let amountSent: Decimal
    public let currencySent: Currency
    public let amountReceived: Decimal
    public let currencyReceived: Currency
    public let exchangeRate: Decimal
    public let fee: Decimal
    public let status: TransactionStatus
    public let reference: String
    public let createdAt: Date
    public let completedAt: Date?
    
    public init(
        id: TransactionID,
        senderId: String,
        recipientId: RecipientID,
        recipientName: String,
        amountSent: Decimal,
        currencySent: Currency,
        amountReceived: Decimal,
        currencyReceived: Currency,
        exchangeRate: Decimal,
        fee: Decimal,
        status: TransactionStatus,
        reference: String,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.senderId = senderId
        self.recipientId = recipientId
        self.recipientName = recipientName
        self.amountSent = amountSent
        self.currencySent = currencySent
        self.amountReceived = amountReceived
        self.currencyReceived = currencyReceived
        self.exchangeRate = exchangeRate
        self.fee = fee
        self.status = status
        self.reference = reference
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
    
    public var totalCost: Decimal {
        amountSent + fee
    }
}

public enum TransactionStatus: String, Equatable, Sendable, CaseIterable {
    case pending = "PENDING"
    case processing = "PROCESSING"
    case completed = "COMPLETED"
    case failed = "FAILED"
    case cancelled = "CANCELLED"
}

// MARK: - Currency

public enum Currency: String, Equatable, Sendable, CaseIterable {
    case ngn = "NGN"
    case usd = "USD"
    case gbp = "GBP"
    case eur = "EUR"
    case cad = "CAD"
    case zar = "ZAR"
    
    public var symbol: String {
        switch self {
        case .ngn: return "₦"
        case .usd: return "$"
        case .gbp: return "£"
        case .eur: return "€"
        case .cad: return "C$"
        case .zar: return "R"
        }
    }
    
    public var name: String {
        switch self {
        case .ngn: return "Nigerian Naira"
        case .usd: return "US Dollar"
        case .gbp: return "British Pound"
        case .eur: return "Euro"
        case .cad: return "Canadian Dollar"
        case .zar: return "South African Rand"
        }
    }
    
    public var flag: String {
        switch self {
        case .ngn: return "🇳🇬"
        case .usd: return "🇺🇸"
        case .gbp: return "🇬🇧"
        case .eur: return "🇪🇺"
        case .cad: return "🇨🇦"
        case .zar: return "🇿🇦"
        }
    }
}

// MARK: - Exchange Rate

public struct ExchangeRate: Equatable, Sendable {
    public let sourceCurrency: Currency
    public let targetCurrency: Currency
    public let rate: Decimal
    public let inverseRate: Decimal
    public let timestamp: Date
    
    public init(
        sourceCurrency: Currency,
        targetCurrency: Currency,
        rate: Decimal,
        inverseRate: Decimal,
        timestamp: Date = Date()
    ) {
        self.sourceCurrency = sourceCurrency
        self.targetCurrency = targetCurrency
        self.rate = rate
        self.inverseRate = inverseRate
        self.timestamp = timestamp
    }
}

// MARK: - Recipient

public struct Recipient: Equatable, Identifiable, Sendable {
    public let id: RecipientID
    public let fullName: String
    public let phoneNumber: String
    public let bankName: String?
    public let bankCode: String?
    public let accountNumber: String?
    public let state: NigerianState?
    public var isFavorite: Bool
    public let createdAt: Date
    
    public init(
        id: RecipientID,
        fullName: String,
        phoneNumber: String,
        bankName: String? = nil,
        bankCode: String? = nil,
        accountNumber: String? = nil,
        state: NigerianState? = nil,
        isFavorite: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.fullName = fullName
        self.phoneNumber = phoneNumber
        self.bankName = bankName
        self.bankCode = bankCode
        self.accountNumber = accountNumber
        self.state = state
        self.isFavorite = isFavorite
        self.createdAt = createdAt
    }
}

// MARK: - Nigerian State

public enum NigerianState: String, Equatable, Sendable, CaseIterable {
    case abia, adamawa, akwaIbom, anambra, bauchi, bayelsa, benue, borno
    case crossRiver, delta, ebonyi, edo, ekiti, enugu, fct, gombe
    case imo, jigawa, kaduna, kano, katsina, kebbi, kogi, kwara
    case lagos, nasarawa, niger, ogun, ondo, osun, oyo, plateau
    case rivers, sokoto, taraba, yobe, zamfara
    
    public var displayName: String {
        switch self {
        case .akwaIbom: return "Akwa Ibom"
        case .crossRiver: return "Cross River"
        case .fct: return "Federal Capital Territory"
        default:
            return rawValue.prefix(1).uppercased() + rawValue.dropFirst()
        }
    }
    
    public var region: GeopoliticalZone {
        switch self {
        case .benue, .fct, .kogi, .kwara, .nasarawa, .niger, .plateau:
            return .northCentral
        case .adamawa, .bauchi, .borno, .gombe, .taraba, .yobe:
            return .northEast
        case .jigawa, .kaduna, .kano, .katsina, .kebbi, .sokoto, .zamfara:
            return .northWest
        case .abia, .anambra, .ebonyi, .enugu, .imo:
            return .southEast
        case .akwaIbom, .bayelsa, .crossRiver, .delta, .edo, .rivers:
            return .southSouth
        case .ekiti, .lagos, .ogun, .ondo, .osun, .oyo:
            return .southWest
        }
    }
}

public enum GeopoliticalZone: String, Equatable, Sendable, CaseIterable {
    case northCentral = "North Central"
    case northEast = "North East"
    case northWest = "North West"
    case southEast = "South East"
    case southSouth = "South South"
    case southWest = "South West"
}

// MARK: - Nigerian Bank

public struct NigerianBank: Equatable, Identifiable, Sendable {
    public let id: String
    public let code: String
    public let name: String
    public let shortName: String
    
    public init(code: String, name: String, shortName: String) {
        self.id = code
        self.code = code
        self.name = name
        self.shortName = shortName
    }
    
    public static let allBanks: [NigerianBank] = [
        NigerianBank(code: "044", name: "Access Bank", shortName: "Access"),
        NigerianBank(code: "023", name: "Citibank Nigeria", shortName: "Citibank"),
        NigerianBank(code: "050", name: "Ecobank Nigeria", shortName: "Ecobank"),
        NigerianBank(code: "070", name: "Fidelity Bank", shortName: "Fidelity"),
        NigerianBank(code: "011", name: "First Bank of Nigeria", shortName: "First Bank"),
        NigerianBank(code: "214", name: "First City Monument Bank", shortName: "FCMB"),
        NigerianBank(code: "058", name: "Guaranty Trust Bank", shortName: "GTBank"),
        NigerianBank(code: "030", name: "Heritage Bank", shortName: "Heritage"),
        NigerianBank(code: "301", name: "Jaiz Bank", shortName: "Jaiz"),
        NigerianBank(code: "082", name: "Keystone Bank", shortName: "Keystone"),
        NigerianBank(code: "101", name: "Providus Bank", shortName: "Providus"),
        NigerianBank(code: "076", name: "Polaris Bank", shortName: "Polaris"),
        NigerianBank(code: "221", name: "Stanbic IBTC Bank", shortName: "Stanbic"),
        NigerianBank(code: "232", name: "Sterling Bank", shortName: "Sterling"),
        NigerianBank(code: "032", name: "Union Bank of Nigeria", shortName: "Union Bank"),
        NigerianBank(code: "033", name: "United Bank for Africa", shortName: "UBA"),
        NigerianBank(code: "215", name: "Unity Bank", shortName: "Unity"),
        NigerianBank(code: "035", name: "Wema Bank", shortName: "Wema"),
        NigerianBank(code: "057", name: "Zenith Bank", shortName: "Zenith"),
        NigerianBank(code: "999", name: "Kuda Bank", shortName: "Kuda"),
        NigerianBank(code: "999", name: "OPay", shortName: "OPay"),
        NigerianBank(code: "999", name: "PalmPay", shortName: "PalmPay"),
        NigerianBank(code: "999", name: "Moniepoint", shortName: "Moniepoint"),
    ]
}
