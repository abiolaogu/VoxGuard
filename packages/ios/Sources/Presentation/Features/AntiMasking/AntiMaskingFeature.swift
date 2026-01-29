import ComposableArchitecture
import Foundation

// MARK: - Anti-Masking Feature Reducer

@Reducer
public struct AntiMaskingFeature {
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        // Form state
        public var callerNumber: String = ""
        public var calleeNumber: String = ""
        public var callerMNO: NigerianMNO = .unknown
        public var calleeMNO: NigerianMNO = .unknown
        
        // Verification state
        public var isVerifying: Bool = false
        public var latestVerification: CallVerification?
        public var verifications: IdentifiedArrayOf<CallVerification> = []
        
        // Alerts state
        public var fraudAlerts: IdentifiedArrayOf<FraudAlert> = []
        public var unacknowledgedAlertCount: Int = 0
        
        // Loading and error states
        public var isLoading: Bool = false
        public var error: String?
        
        // Filter state
        public var showMaskingDetectedOnly: Bool = false
        
        // Alert dialog
        @Presents public var alert: AlertState<Action.Alert>?
        
        // Computed
        public var canVerify: Bool {
            callerNumber.count >= 10 && calleeNumber.count >= 10 && !isVerifying
        }
        
        public init() {}
    }
    
    // MARK: - Action
    
    public enum Action: Equatable {
        // Form actions
        case callerNumberChanged(String)
        case calleeNumberChanged(String)
        
        // Verification actions
        case verifyCall
        case verificationResponse(Result<CallVerification, Error>)
        case loadHistory
        case historyResponse(Result<[CallVerification], Error>)
        case toggleMaskingFilter
        
        // Reporting
        case reportToNCC(VerificationID)
        case reportResponse(Result<Void, Error>)
        
        // Alerts
        case loadAlerts
        case alertsResponse(Result<[FraudAlert], Error>)
        case acknowledgeAlert(AlertID)
        case acknowledgeResponse(Result<Void, Error>)
        
        // Real-time updates
        case subscribeToVerifications
        case newVerificationReceived(CallVerification)
        case newFraudAlertReceived(FraudAlert)
        
        // Alert dialog
        case alert(PresentationAction<Alert>)
        
        // Navigation
        case verificationTapped(VerificationID)
        
        // Error handling
        case clearError
        
        public enum Alert: Equatable {
            case reportToNCC
            case dismiss
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.antiMaskingClient) var client
    @Dependency(\.hapticClient) var haptics
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                
            // MARK: Form Actions
                
            case let .callerNumberChanged(number):
                state.callerNumber = number
                state.callerMNO = NigerianMNO.detect(from: number)
                state.error = nil
                return .none
                
            case let .calleeNumberChanged(number):
                state.calleeNumber = number
                state.calleeMNO = NigerianMNO.detect(from: number)
                state.error = nil
                return .none
                
            // MARK: Verification Actions
                
            case .verifyCall:
                guard state.canVerify else { return .none }
                state.isVerifying = true
                state.error = nil
                
                let caller = state.callerNumber
                let callee = state.calleeNumber
                
                return .run { send in
                    await send(.verificationResponse(
                        Result { try await client.verifyCall(caller, callee) }
                    ))
                }
                
            case let .verificationResponse(.success(verification)):
                state.isVerifying = false
                state.latestVerification = verification
                state.verifications.insert(verification, at: 0)
                
                if verification.maskingDetected {
                    // Trigger haptic feedback
                    return .merge(
                        .run { _ in await haptics.heavy() },
                        .run { send in
                            await send(.alert(.presented(.reportToNCC)))
                        }
                    )
                }
                return .none
                
            case let .verificationResponse(.failure(error)):
                state.isVerifying = false
                state.error = error.localizedDescription
                return .none
                
            case .loadHistory:
                state.isLoading = true
                let maskingOnly = state.showMaskingDetectedOnly
                
                return .run { send in
                    await send(.historyResponse(
                        Result { try await client.getVerifications(20, 0, maskingOnly) }
                    ))
                }
                
            case let .historyResponse(.success(verifications)):
                state.isLoading = false
                state.verifications = IdentifiedArray(uniqueElements: verifications)
                return .none
                
            case let .historyResponse(.failure(error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none
                
            case .toggleMaskingFilter:
                state.showMaskingDetectedOnly.toggle()
                return .send(.loadHistory)
                
            // MARK: Reporting Actions
                
            case let .reportToNCC(verificationId):
                state.isLoading = true
                
                return .run { send in
                    await send(.reportResponse(
                        Result { try await client.reportMasking(verificationId.rawValue.uuidString, nil) }
                    ))
                }
                
            case .reportResponse(.success):
                state.isLoading = false
                // Show success feedback
                return .run { _ in await haptics.success() }
                
            case let .reportResponse(.failure(error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none
                
            // MARK: Alert Actions
                
            case .loadAlerts:
                return .run { send in
                    await send(.alertsResponse(
                        Result { try await client.getFraudAlerts(20, nil) }
                    ))
                }
                
            case let .alertsResponse(.success(alerts)):
                state.fraudAlerts = IdentifiedArray(uniqueElements: alerts)
                state.unacknowledgedAlertCount = alerts.filter { !$0.isAcknowledged }.count
                return .none
                
            case let .alertsResponse(.failure(error)):
                state.error = error.localizedDescription
                return .none
                
            case let .acknowledgeAlert(alertId):
                return .run { send in
                    await send(.acknowledgeResponse(
                        Result { try await client.acknowledgeAlert(alertId.rawValue.uuidString) }
                    ))
                }
                
            case .acknowledgeResponse(.success):
                return .send(.loadAlerts)
                
            case let .acknowledgeResponse(.failure(error)):
                state.error = error.localizedDescription
                return .none
                
            // MARK: Real-time Updates
                
            case .subscribeToVerifications:
                return .run { send in
                    for await verification in client.observeVerifications() {
                        await send(.newVerificationReceived(verification))
                    }
                }
                
            case let .newVerificationReceived(verification):
                state.verifications.insert(verification, at: 0)
                if state.verifications.count > 20 {
                    state.verifications.removeLast()
                }
                
                if verification.maskingDetected {
                    return .run { _ in await haptics.heavy() }
                }
                return .none
                
            case let .newFraudAlertReceived(alert):
                state.fraudAlerts.insert(alert, at: 0)
                state.unacknowledgedAlertCount += 1
                return .run { _ in await haptics.heavy() }
                
            // MARK: Alert Dialog
                
            case .alert(.presented(.reportToNCC)):
                guard let verification = state.latestVerification else { return .none }
                state.alert = AlertState {
                    TextState("CLI Masking Detected!")
                } actions: {
                    ButtonState(action: .reportToNCC) {
                        TextState("Report to NCC")
                    }
                    ButtonState(role: .cancel, action: .dismiss) {
                        TextState("Dismiss")
                    }
                } message: {
                    TextState("Suspicious activity detected on \(verification.callerNumber). Confidence: \(Int(verification.confidenceScore * 100))%")
                }
                return .none
                
            case .alert(.presented(.dismiss)):
                state.alert = nil
                return .none
                
            case .alert(.dismiss):
                state.alert = nil
                return .none
                
            // MARK: Navigation
                
            case .verificationTapped:
                // Handle navigation to details
                return .none
                
            // MARK: Error Handling
                
            case .clearError:
                state.error = nil
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
    
    public init() {}
}

// MARK: - Error Extension

extension Error {
    var equatable: EquatableError { EquatableError(self) }
}

public struct EquatableError: Error, Equatable {
    let error: Error
    
    init(_ error: Error) {
        self.error = error
    }
    
    public static func == (lhs: EquatableError, rhs: EquatableError) -> Bool {
        lhs.error.localizedDescription == rhs.error.localizedDescription
    }
}

// MARK: - Result Extension for Void

extension Result where Success == Void {
    static var success: Result { .success(()) }
}
