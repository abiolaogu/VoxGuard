import Foundation
import Tagged

// MARK: - Call Verification

/// Unique identifier for a call verification
public typealias VerificationID = Tagged<CallVerification, UUID>

/// Represents a call verification result
public struct CallVerification: Equatable, Identifiable, Sendable {
    public let id: VerificationID
    public let callerNumber: String
    public let calleeNumber: String
    public let originalCLI: String
    public let detectedCLI: String?
    public let maskingDetected: Bool
    public let confidenceScore: Double
    public let status: VerificationStatus
    public let gatewayName: String?
    public let detectedMno: NigerianMNO?
    public let verifiedAt: Date
    public let createdAt: Date
    
    public init(
        id: VerificationID,
        callerNumber: String,
        calleeNumber: String,
        originalCLI: String,
        detectedCLI: String? = nil,
        maskingDetected: Bool,
        confidenceScore: Double,
        status: VerificationStatus,
        gatewayName: String? = nil,
        detectedMno: NigerianMNO? = nil,
        verifiedAt: Date = Date(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.callerNumber = callerNumber
        self.calleeNumber = calleeNumber
        self.originalCLI = originalCLI
        self.detectedCLI = detectedCLI
        self.maskingDetected = maskingDetected
        self.confidenceScore = confidenceScore
        self.status = status
        self.gatewayName = gatewayName
        self.detectedMno = detectedMno
        self.verifiedAt = verifiedAt
        self.createdAt = createdAt
    }
    
    public var riskLevel: RiskLevel {
        switch confidenceScore {
        case 0.9...: return .critical
        case 0.7..<0.9: return .high
        case 0.5..<0.7: return .medium
        default: return .low
        }
    }
    
    public var isSafe: Bool {
        !maskingDetected && confidenceScore < 0.5
    }
}

public enum VerificationStatus: String, Equatable, Sendable, CaseIterable {
    case pending = "PENDING"
    case verifying = "VERIFYING"
    case verified = "VERIFIED"
    case maskingDetected = "MASKING_DETECTED"
    case failed = "FAILED"
}

public enum RiskLevel: String, Equatable, Sendable, CaseIterable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case critical = "CRITICAL"
    
    public var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}

// MARK: - Fraud Alert

public typealias AlertID = Tagged<FraudAlert, UUID>

public struct FraudAlert: Equatable, Identifiable, Sendable {
    public let id: AlertID
    public let verificationId: VerificationID
    public let severity: AlertSeverity
    public let title: String
    public let message: String
    public let callerNumber: String
    public let detectedMno: NigerianMNO?
    public var isAcknowledged: Bool
    public let createdAt: Date
    
    public init(
        id: AlertID,
        verificationId: VerificationID,
        severity: AlertSeverity,
        title: String,
        message: String,
        callerNumber: String,
        detectedMno: NigerianMNO? = nil,
        isAcknowledged: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.verificationId = verificationId
        self.severity = severity
        self.title = title
        self.message = message
        self.callerNumber = callerNumber
        self.detectedMno = detectedMno
        self.isAcknowledged = isAcknowledged
        self.createdAt = createdAt
    }
}

public enum AlertSeverity: String, Equatable, Sendable, CaseIterable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case critical = "CRITICAL"
}

// MARK: - Nigerian MNO

public enum NigerianMNO: String, Equatable, Sendable, CaseIterable {
    case mtn = "MTN"
    case glo = "GLO"
    case airtel = "AIRTEL"
    case nineMobile = "9MOBILE"
    case unknown = "UNKNOWN"
    
    public var displayName: String {
        switch self {
        case .mtn: return "MTN Nigeria"
        case .glo: return "Globacom"
        case .airtel: return "Airtel Nigeria"
        case .nineMobile: return "9mobile"
        case .unknown: return "Unknown"
        }
    }
    
    public var prefixes: [String] {
        switch self {
        case .mtn: return ["0703", "0706", "0803", "0806", "0810", "0813", "0814", "0816", "0903", "0906", "0913"]
        case .glo: return ["0705", "0805", "0807", "0811", "0815", "0905"]
        case .airtel: return ["0701", "0708", "0802", "0808", "0812", "0901", "0902", "0904", "0907", "0912"]
        case .nineMobile: return ["0809", "0817", "0818", "0908", "0909"]
        case .unknown: return []
        }
    }
    
    public static func detect(from phoneNumber: String) -> NigerianMNO {
        let normalized = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        let prefix: String
        if normalized.hasPrefix("234") && normalized.count >= 7 {
            prefix = "0" + String(normalized.dropFirst(3).prefix(3))
        } else if normalized.hasPrefix("0") && normalized.count >= 4 {
            prefix = String(normalized.prefix(4))
        } else {
            return .unknown
        }
        
        for mno in NigerianMNO.allCases where mno != .unknown {
            if mno.prefixes.contains(where: { prefix.hasPrefix($0) }) {
                return mno
            }
        }
        
        return .unknown
    }
}
