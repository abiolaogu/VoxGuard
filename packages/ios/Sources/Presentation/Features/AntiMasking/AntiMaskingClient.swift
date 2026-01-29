import Dependencies
import Foundation

// MARK: - Anti-Masking Client Dependency

public struct AntiMaskingClient: Sendable {
    /// Verify a call between caller and callee
    public var verifyCall: @Sendable (String, String) async throws -> CallVerification
    
    /// Get verification history
    public var getVerifications: @Sendable (Int, Int, Bool?) async throws -> [CallVerification]
    
    /// Get verification by ID
    public var getVerification: @Sendable (String) async throws -> CallVerification
    
    /// Report masking to NCC
    public var reportMasking: @Sendable (String, String?) async throws -> Void
    
    /// Get fraud alerts
    public var getFraudAlerts: @Sendable (Int, Bool?) async throws -> [FraudAlert]
    
    /// Acknowledge fraud alert
    public var acknowledgeAlert: @Sendable (String) async throws -> Void
    
    /// Subscribe to real-time verifications
    public var observeVerifications: @Sendable () -> AsyncStream<CallVerification>
    
    /// Subscribe to real-time fraud alerts
    public var observeAlerts: @Sendable () -> AsyncStream<FraudAlert>
    
    public init(
        verifyCall: @escaping @Sendable (String, String) async throws -> CallVerification,
        getVerifications: @escaping @Sendable (Int, Int, Bool?) async throws -> [CallVerification],
        getVerification: @escaping @Sendable (String) async throws -> CallVerification,
        reportMasking: @escaping @Sendable (String, String?) async throws -> Void,
        getFraudAlerts: @escaping @Sendable (Int, Bool?) async throws -> [FraudAlert],
        acknowledgeAlert: @escaping @Sendable (String) async throws -> Void,
        observeVerifications: @escaping @Sendable () -> AsyncStream<CallVerification>,
        observeAlerts: @escaping @Sendable () -> AsyncStream<FraudAlert>
    ) {
        self.verifyCall = verifyCall
        self.getVerifications = getVerifications
        self.getVerification = getVerification
        self.reportMasking = reportMasking
        self.getFraudAlerts = getFraudAlerts
        self.acknowledgeAlert = acknowledgeAlert
        self.observeVerifications = observeVerifications
        self.observeAlerts = observeAlerts
    }
}

// MARK: - Dependency Key

extension AntiMaskingClient: DependencyKey {
    public static var liveValue: AntiMaskingClient {
        AntiMaskingClient(
            verifyCall: { caller, callee in
                // TODO: Replace with actual GraphQL call
                try await Task.sleep(nanoseconds: 1_500_000_000) // Simulate network
                
                let isMasking = Bool.random()
                let confidence = isMasking ? Double.random(in: 0.7...0.99) : Double.random(in: 0.1...0.4)
                
                return CallVerification(
                    id: .init(rawValue: UUID()),
                    callerNumber: caller.normalized,
                    calleeNumber: callee.normalized,
                    originalCLI: caller.normalized,
                    detectedCLI: isMasking ? "+234\(Int.random(in: 700000000...999999999))" : nil,
                    maskingDetected: isMasking,
                    confidenceScore: confidence,
                    status: isMasking ? .maskingDetected : .verified,
                    gatewayName: "GTW-Lagos-001",
                    detectedMno: NigerianMNO.detect(from: caller),
                    verifiedAt: Date(),
                    createdAt: Date()
                )
            },
            getVerifications: { limit, offset, maskingOnly in
                try await Task.sleep(nanoseconds: 500_000_000)
                
                return (0..<limit).map { index in
                    let isMasking = maskingOnly ?? Bool.random()
                    return CallVerification(
                        id: .init(rawValue: UUID()),
                        callerNumber: "+234\(Int.random(in: 700000000...999999999))",
                        calleeNumber: "+234\(Int.random(in: 700000000...999999999))",
                        originalCLI: "+234\(Int.random(in: 700000000...999999999))",
                        detectedCLI: isMasking ? "+234\(Int.random(in: 700000000...999999999))" : nil,
                        maskingDetected: isMasking,
                        confidenceScore: isMasking ? Double.random(in: 0.7...0.99) : Double.random(in: 0.1...0.4),
                        status: isMasking ? .maskingDetected : .verified,
                        gatewayName: "GTW-Lagos-00\(index)",
                        detectedMno: NigerianMNO.allCases.randomElement() ?? .mtn,
                        verifiedAt: Date().addingTimeInterval(TimeInterval(-index * 3600)),
                        createdAt: Date().addingTimeInterval(TimeInterval(-index * 3600))
                    )
                }
            },
            getVerification: { id in
                try await Task.sleep(nanoseconds: 300_000_000)
                
                return CallVerification(
                    id: .init(rawValue: UUID(uuidString: id) ?? UUID()),
                    callerNumber: "+2348030000000",
                    calleeNumber: "+2349010000000",
                    originalCLI: "+2348030000000",
                    maskingDetected: false,
                    confidenceScore: 0.2,
                    status: .verified,
                    gatewayName: "GTW-Lagos-001",
                    detectedMno: .mtn
                )
            },
            reportMasking: { _, _ in
                try await Task.sleep(nanoseconds: 1_000_000_000)
                // Success
            },
            getFraudAlerts: { limit, acknowledged in
                try await Task.sleep(nanoseconds: 400_000_000)
                
                return (0..<min(limit, 5)).map { index in
                    FraudAlert(
                        id: .init(rawValue: UUID()),
                        verificationId: .init(rawValue: UUID()),
                        severity: AlertSeverity.allCases.randomElement() ?? .high,
                        title: "CLI Masking Detected",
                        message: "Suspicious activity from +234\(Int.random(in: 700000000...999999999))",
                        callerNumber: "+234\(Int.random(in: 700000000...999999999))",
                        detectedMno: NigerianMNO.allCases.randomElement(),
                        isAcknowledged: acknowledged ?? (index > 3),
                        createdAt: Date().addingTimeInterval(TimeInterval(-index * 1800))
                    )
                }
            },
            acknowledgeAlert: { _ in
                try await Task.sleep(nanoseconds: 300_000_000)
            },
            observeVerifications: {
                AsyncStream { continuation in
                    Task {
                        while !Task.isCancelled {
                            try? await Task.sleep(nanoseconds: 30_000_000_000) // Every 30 seconds
                            
                            let isMasking = Bool.random()
                            let verification = CallVerification(
                                id: .init(rawValue: UUID()),
                                callerNumber: "+234\(Int.random(in: 700000000...999999999))",
                                calleeNumber: "+234\(Int.random(in: 700000000...999999999))",
                                originalCLI: "+234\(Int.random(in: 700000000...999999999))",
                                detectedCLI: isMasking ? "+234\(Int.random(in: 700000000...999999999))" : nil,
                                maskingDetected: isMasking,
                                confidenceScore: isMasking ? 0.85 : 0.2,
                                status: isMasking ? .maskingDetected : .verified,
                                gatewayName: "GTW-Lagos-001",
                                detectedMno: .mtn
                            )
                            continuation.yield(verification)
                        }
                    }
                }
            },
            observeAlerts: {
                AsyncStream { continuation in
                    Task {
                        while !Task.isCancelled {
                            try? await Task.sleep(nanoseconds: 60_000_000_000) // Every 60 seconds
                            
                            let alert = FraudAlert(
                                id: .init(rawValue: UUID()),
                                verificationId: .init(rawValue: UUID()),
                                severity: .high,
                                title: "New Masking Alert",
                                message: "Suspicious CLI detected",
                                callerNumber: "+234\(Int.random(in: 700000000...999999999))",
                                detectedMno: .mtn,
                                isAcknowledged: false
                            )
                            continuation.yield(alert)
                        }
                    }
                }
            }
        )
    }
    
    public static var testValue: AntiMaskingClient {
        AntiMaskingClient(
            verifyCall: { _, _ in
                CallVerification(
                    id: .init(rawValue: UUID()),
                    callerNumber: "+2348030001234",
                    calleeNumber: "+2349010005678",
                    originalCLI: "+2348030001234",
                    maskingDetected: false,
                    confidenceScore: 0.2,
                    status: .verified
                )
            },
            getVerifications: { _, _, _ in [] },
            getVerification: { _ in fatalError() },
            reportMasking: { _, _ in },
            getFraudAlerts: { _, _ in [] },
            acknowledgeAlert: { _ in },
            observeVerifications: { AsyncStream { _ in } },
            observeAlerts: { AsyncStream { _ in } }
        )
    }
}

extension DependencyValues {
    public var antiMaskingClient: AntiMaskingClient {
        get { self[AntiMaskingClient.self] }
        set { self[AntiMaskingClient.self] = newValue }
    }
}

// MARK: - String Extension

private extension String {
    var normalized: String {
        let cleaned = replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        if cleaned.hasPrefix("0") {
            return "+234\(cleaned.dropFirst())"
        } else if cleaned.hasPrefix("234") {
            return "+\(cleaned)"
        }
        return "+234\(cleaned)"
    }
}
