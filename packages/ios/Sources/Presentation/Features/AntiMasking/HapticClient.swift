import Dependencies
import UIKit

// MARK: - Haptic Client

public struct HapticClient: Sendable {
    public var light: @Sendable () async -> Void
    public var medium: @Sendable () async -> Void
    public var heavy: @Sendable () async -> Void
    public var success: @Sendable () async -> Void
    public var warning: @Sendable () async -> Void
    public var error: @Sendable () async -> Void
    public var selection: @Sendable () async -> Void
    
    public init(
        light: @escaping @Sendable () async -> Void,
        medium: @escaping @Sendable () async -> Void,
        heavy: @escaping @Sendable () async -> Void,
        success: @escaping @Sendable () async -> Void,
        warning: @escaping @Sendable () async -> Void,
        error: @escaping @Sendable () async -> Void,
        selection: @escaping @Sendable () async -> Void
    ) {
        self.light = light
        self.medium = medium
        self.heavy = heavy
        self.success = success
        self.warning = warning
        self.error = error
        self.selection = selection
    }
}

extension HapticClient: DependencyKey {
    public static var liveValue: HapticClient {
        HapticClient(
            light: {
                await MainActor.run {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            },
            medium: {
                await MainActor.run {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            },
            heavy: {
                await MainActor.run {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                }
            },
            success: {
                await MainActor.run {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            },
            warning: {
                await MainActor.run {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                }
            },
            error: {
                await MainActor.run {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            },
            selection: {
                await MainActor.run {
                    UISelectionFeedbackGenerator().selectionChanged()
                }
            }
        )
    }
    
    public static var testValue: HapticClient {
        HapticClient(
            light: {},
            medium: {},
            heavy: {},
            success: {},
            warning: {},
            error: {},
            selection: {}
        )
    }
}

extension DependencyValues {
    public var hapticClient: HapticClient {
        get { self[HapticClient.self] }
        set { self[HapticClient.self] = newValue }
    }
}
