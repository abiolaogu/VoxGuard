import ComposableArchitecture
import Foundation

// MARK: - Fraud Prevention Feature (TCA)

@Reducer
struct FraudDashboardFeature {
    @ObservableState
    struct State: Equatable {
        var summary: FraudSummary = FraudSummary()
        var isLoading: Bool = false
        var errorMessage: String?
        
        var cliVerifications: IdentifiedArrayOf<CLIVerification> = []
        var irsfIncidents: IdentifiedArrayOf<IRSFIncident> = []
        var wangiriIncidents: IdentifiedArrayOf<WangiriIncident> = []
    }
    
    enum Action: Equatable {
        case onAppear
        case refresh
        case summaryLoaded(FraudSummary)
        case loadFailed(String)
        case cliVerificationsLoaded([CLIVerification])
        case irsfIncidentsLoaded([IRSFIncident])
        case wangiriIncidentsLoaded([WangiriIncident])
        case blockNumber(String)
        case blockNumberResult(Result<Void, Error>)
        
        static func == (lhs: Action, rhs: Action) -> Bool {
            switch (lhs, rhs) {
            case (.onAppear, .onAppear): return true
            case (.refresh, .refresh): return true
            case let (.summaryLoaded(l), .summaryLoaded(r)): return l == r
            case let (.loadFailed(l), .loadFailed(r)): return l == r
            case let (.blockNumber(l), .blockNumber(r)): return l == r
            default: return false
            }
        }
    }
    
    @Dependency(\.fraudClient) var fraudClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    let summary = try await fraudClient.getFraudSummary()
                    await send(.summaryLoaded(summary))
                } catch: { error, send in
                    await send(.loadFailed(error.localizedDescription))
                }
                
            case .refresh:
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    let summary = try await fraudClient.getFraudSummary()
                    await send(.summaryLoaded(summary))
                } catch: { error, send in
                    await send(.loadFailed(error.localizedDescription))
                }
                
            case let .summaryLoaded(summary):
                state.isLoading = false
                state.summary = summary
                return .none
                
            case let .loadFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none
                
            case let .cliVerificationsLoaded(items):
                state.cliVerifications = IdentifiedArray(uniqueElements: items)
                return .none
                
            case let .irsfIncidentsLoaded(items):
                state.irsfIncidents = IdentifiedArray(uniqueElements: items)
                return .none
                
            case let .wangiriIncidentsLoaded(items):
                state.wangiriIncidents = IdentifiedArray(uniqueElements: items)
                return .none
                
            case let .blockNumber(number):
                return .run { send in
                    try await fraudClient.blockNumber(number)
                    await send(.blockNumberResult(.success(())))
                } catch: { error, send in
                    await send(.blockNumberResult(.failure(error)))
                }
                
            case .blockNumberResult:
                return .none
            }
        }
    }
}

// MARK: - Domain Models

struct FraudSummary: Equatable, Codable {
    var cliSpoofingCount: Int = 0
    var irsfCount: Int = 0
    var wangiriCount: Int = 0
    var callbackFraudCount: Int = 0
    var totalRevenueProtected: Double = 0
}

struct CLIVerification: Equatable, Identifiable, Codable {
    let id: String
    let presentedCli: String
    let actualCli: String?
    let spoofingDetected: Bool
    let spoofingType: String?
    let confidenceScore: Double?
    let createdAt: Date
}

struct IRSFIncident: Equatable, Identifiable, Codable {
    let id: String
    let sourceNumber: String
    let destinationNumber: String
    let destinationCountry: String
    let riskScore: Double
    let estimatedLoss: Double?
    let actionTaken: String?
    let createdAt: Date
}

struct WangiriIncident: Equatable, Identifiable, Codable {
    let id: String
    let sourceNumber: String
    let targetNumber: String
    let ringDurationMs: Int
    let confidenceScore: Double
    let callbackAttempted: Bool
    let callbackBlocked: Bool
    let createdAt: Date
}

// MARK: - Fraud Client Dependency

struct FraudClient {
    var getFraudSummary: @Sendable () async throws -> FraudSummary
    var getCLIVerifications: @Sendable () async throws -> [CLIVerification]
    var getIRSFIncidents: @Sendable () async throws -> [IRSFIncident]
    var getWangiriIncidents: @Sendable () async throws -> [WangiriIncident]
    var blockNumber: @Sendable (String) async throws -> Void
}

extension FraudClient: DependencyKey {
    static let liveValue = FraudClient(
        getFraudSummary: {
            // API call implementation
            return FraudSummary(
                cliSpoofingCount: 47,
                irsfCount: 23,
                wangiriCount: 156,
                callbackFraudCount: 12,
                totalRevenueProtected: 15420000
            )
        },
        getCLIVerifications: { [] },
        getIRSFIncidents: { [] },
        getWangiriIncidents: { [] },
        blockNumber: { _ in }
    )
    
    static let testValue = FraudClient(
        getFraudSummary: { FraudSummary() },
        getCLIVerifications: { [] },
        getIRSFIncidents: { [] },
        getWangiriIncidents: { [] },
        blockNumber: { _ in }
    )
}

extension DependencyValues {
    var fraudClient: FraudClient {
        get { self[FraudClient.self] }
        set { self[FraudClient.self] = newValue }
    }
}
