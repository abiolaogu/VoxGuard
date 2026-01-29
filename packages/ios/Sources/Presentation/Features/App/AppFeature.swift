import ComposableArchitecture
import Foundation

// MARK: - App Feature (Root Reducer)

@Reducer
public struct AppFeature {
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public var selectedTab: Tab = .antiMasking
        public var antiMasking: AntiMaskingFeature.State = .init()
        public var remittance: RemittanceFeature.State = .init()
        public var marketplace: MarketplaceFeature.State = .init()
        
        public init() {}
    }
    
    public enum Tab: String, Equatable, CaseIterable {
        case antiMasking = "Verify"
        case remittance = "Send Money"
        case marketplace = "Market"
        case settings = "Settings"
        
        public var icon: String {
            switch self {
            case .antiMasking: return "shield.checkered"
            case .remittance: return "paperplane.fill"
            case .marketplace: return "storefront.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case tabSelected(Tab)
        case antiMasking(AntiMaskingFeature.Action)
        case remittance(RemittanceFeature.Action)
        case marketplace(MarketplaceFeature.Action)
    }
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Scope(state: \.antiMasking, action: \.antiMasking) {
            AntiMaskingFeature()
        }
        
        Scope(state: \.remittance, action: \.remittance) {
            RemittanceFeature()
        }
        
        Scope(state: \.marketplace, action: \.marketplace) {
            MarketplaceFeature()
        }
        
        Reduce { state, action in
            switch action {
            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none
                
            case .antiMasking, .remittance, .marketplace:
                return .none
            }
        }
    }
    
    public init() {}
}
