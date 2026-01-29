import ComposableArchitecture
import Foundation
import XCTest

@testable import ACMPresentation

final class AntiMaskingFeatureTests: XCTestCase {
    
    @MainActor
    func testCallerNumberChanged_UpdatesStateAndDetectsMNO() async {
        let store = TestStore(initialState: AntiMaskingFeature.State()) {
            AntiMaskingFeature()
        } withDependencies: {
            $0.antiMaskingClient = .testValue
            $0.hapticClient = .testValue
        }
        
        await store.send(.callerNumberChanged("08030001234")) {
            $0.callerNumber = "08030001234"
            $0.callerMNO = .mtn
            $0.error = nil
        }
    }
    
    @MainActor
    func testCanVerify_RequiresBothValidNumbers() async {
        let store = TestStore(initialState: AntiMaskingFeature.State()) {
            AntiMaskingFeature()
        } withDependencies: {
            $0.antiMaskingClient = .testValue
            $0.hapticClient = .testValue
        }
        
        XCTAssertFalse(store.state.canVerify)
        
        await store.send(.callerNumberChanged("08030001234")) {
            $0.callerNumber = "08030001234"
            $0.callerMNO = .mtn
        }
        
        XCTAssertFalse(store.state.canVerify)
        
        await store.send(.calleeNumberChanged("09010005678")) {
            $0.calleeNumber = "09010005678"
            $0.calleeMNO = .nineMobile
        }
        
        XCTAssertTrue(store.state.canVerify)
    }
    
    @MainActor
    func testVerifyCall_Success_UpdatesState() async {
        let mockVerification = CallVerification(
            id: .init(rawValue: UUID()),
            callerNumber: "+2348030001234",
            calleeNumber: "+2349010005678",
            originalCLI: "+2348030001234",
            maskingDetected: false,
            confidenceScore: 0.2,
            status: .verified
        )
        
        let store = TestStore(initialState: {
            var state = AntiMaskingFeature.State()
            state.callerNumber = "08030001234"
            state.calleeNumber = "09010005678"
            return state
        }()) {
            AntiMaskingFeature()
        } withDependencies: {
            $0.antiMaskingClient.verifyCall = { _, _ in mockVerification }
            $0.hapticClient = .testValue
        }
        
        await store.send(.verifyCall) {
            $0.isVerifying = true
            $0.error = nil
        }
        
        await store.receive(\.verificationResponse.success) {
            $0.isVerifying = false
            $0.latestVerification = mockVerification
            $0.verifications = [mockVerification]
        }
    }
    
    @MainActor
    func testVerifyCall_MaskingDetected_TriggersHaptic() async {
        let mockVerification = CallVerification(
            id: .init(rawValue: UUID()),
            callerNumber: "+2348030001234",
            calleeNumber: "+2349010005678",
            originalCLI: "+2348030001234",
            detectedCLI: "+2348099999999",
            maskingDetected: true,
            confidenceScore: 0.85,
            status: .maskingDetected
        )
        
        var hapticTriggered = false
        
        let store = TestStore(initialState: {
            var state = AntiMaskingFeature.State()
            state.callerNumber = "08030001234"
            state.calleeNumber = "09010005678"
            return state
        }()) {
            AntiMaskingFeature()
        } withDependencies: {
            $0.antiMaskingClient.verifyCall = { _, _ in mockVerification }
            $0.hapticClient.heavy = { hapticTriggered = true }
        }
        
        await store.send(.verifyCall) {
            $0.isVerifying = true
        }
        
        await store.receive(\.verificationResponse.success) {
            $0.isVerifying = false
            $0.latestVerification = mockVerification
            $0.verifications = [mockVerification]
        }
        
        // The reducer triggers haptic and alert for masking
        await store.receive(\.alert.presented.reportToNCC) {
            $0.alert = AlertState {
                TextState("CLI Masking Detected!")
            } actions: {
                ButtonState(action: .reportToNCC) {
                    TextState("Report to NCC")
                }
                ButtonState(role: .cancel, action: .dismiss) {
                    TextState("Dismiss")
                }
            } message: {
                TextState("Suspicious activity detected on +2348030001234. Confidence: 85%")
            }
        }
        
        XCTAssertTrue(hapticTriggered)
    }
    
    @MainActor
    func testVerifyCall_Failure_SetsError() async {
        struct TestError: Error, LocalizedError {
            var errorDescription: String? { "Network error" }
        }
        
        let store = TestStore(initialState: {
            var state = AntiMaskingFeature.State()
            state.callerNumber = "08030001234"
            state.calleeNumber = "09010005678"
            return state
        }()) {
            AntiMaskingFeature()
        } withDependencies: {
            $0.antiMaskingClient.verifyCall = { _, _ in throw TestError() }
            $0.hapticClient = .testValue
        }
        
        await store.send(.verifyCall) {
            $0.isVerifying = true
        }
        
        await store.receive(\.verificationResponse.failure) {
            $0.isVerifying = false
            $0.error = "Network error"
        }
    }
    
    @MainActor
    func testToggleMaskingFilter_UpdatesAndReloads() async {
        let store = TestStore(initialState: AntiMaskingFeature.State()) {
            AntiMaskingFeature()
        } withDependencies: {
            $0.antiMaskingClient.getVerifications = { _, _, _ in [] }
            $0.hapticClient = .testValue
        }
        
        await store.send(.toggleMaskingFilter) {
            $0.showMaskingDetectedOnly = true
        }
        
        await store.receive(\.loadHistory) {
            $0.isLoading = true
        }
        
        await store.receive(\.historyResponse.success) {
            $0.isLoading = false
            $0.verifications = []
        }
    }
    
    @MainActor
    func testLoadAlerts_PopulatesAlertsAndCount() async {
        let mockAlerts = [
            FraudAlert(
                id: .init(rawValue: UUID()),
                verificationId: .init(rawValue: UUID()),
                severity: .high,
                title: "Alert 1",
                message: "Test",
                callerNumber: "+2348030000000",
                isAcknowledged: false
            ),
            FraudAlert(
                id: .init(rawValue: UUID()),
                verificationId: .init(rawValue: UUID()),
                severity: .medium,
                title: "Alert 2",
                message: "Test 2",
                callerNumber: "+2348060000000",
                isAcknowledged: true
            )
        ]
        
        let store = TestStore(initialState: AntiMaskingFeature.State()) {
            AntiMaskingFeature()
        } withDependencies: {
            $0.antiMaskingClient.getFraudAlerts = { _, _ in mockAlerts }
            $0.hapticClient = .testValue
        }
        
        await store.send(.loadAlerts)
        
        await store.receive(\.alertsResponse.success) {
            $0.fraudAlerts = IdentifiedArray(uniqueElements: mockAlerts)
            $0.unacknowledgedAlertCount = 1
        }
    }
    
    @MainActor
    func testClearError_RemovesError() async {
        let store = TestStore(initialState: {
            var state = AntiMaskingFeature.State()
            state.error = "Some error"
            return state
        }()) {
            AntiMaskingFeature()
        } withDependencies: {
            $0.antiMaskingClient = .testValue
            $0.hapticClient = .testValue
        }
        
        await store.send(.clearError) {
            $0.error = nil
        }
    }
}
