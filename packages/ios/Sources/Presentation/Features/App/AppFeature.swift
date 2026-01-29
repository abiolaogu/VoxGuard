import ComposableArchitecture
import Foundation

// MARK: - App Feature (Root Reducer)
// Cleaned: Anti-Call Masking Only

@Reducer
public struct AppFeature {
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public var selectedTab: Tab = .antiMasking
        public var antiMasking: AntiMaskingFeature.State = .init()
        
        public init() {}
    }
    
    public enum Tab: String, Equatable, CaseIterable {
        case antiMasking = "Verify"
        case reports = "Reports"
        case carriers = "Carriers"
        case settings = "Settings"
        
        public var icon: String {
            switch self {
            case .antiMasking: return "shield.checkered"
            case .reports: return "doc.text.fill"
            case .carriers: return "antenna.radiowaves.left.and.right"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case tabSelected(Tab)
        case antiMasking(AntiMaskingFeature.Action)
    }
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Scope(state: \.antiMasking, action: \.antiMasking) {
            AntiMaskingFeature()
        }
        
        Reduce { state, action in
            switch action {
            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none
                
            case .antiMasking:
                return .none
            }
        }
    }
    
    public init() {}
}

