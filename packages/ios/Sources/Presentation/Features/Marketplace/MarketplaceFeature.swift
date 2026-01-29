import ComposableArchitecture
import Foundation

// MARK: - Marketplace Feature Reducer

@Reducer
public struct MarketplaceFeature {
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        // Listings
        public var listings: IdentifiedArrayOf<MarketplaceListing> = []
        public var featuredListings: IdentifiedArrayOf<MarketplaceListing> = []
        public var favorites: IdentifiedArrayOf<MarketplaceListing> = []
        
        // Filters
        public var searchQuery: String = ""
        public var selectedCategory: ListingCategory?
        public var selectedState: NigerianState?
        public var showDiasporaFriendlyOnly: Bool = false
        
        // Loading states
        public var isLoading: Bool = false
        public var isLoadingMore: Bool = false
        
        // Error
        public var error: String?
        
        public init() {}
    }
    
    // MARK: - Action
    
    public enum Action: Equatable {
        // Listings
        case loadListings
        case loadMoreListings
        case listingsResponse(Result<[MarketplaceListing], Error>)
        case loadFeatured
        case featuredResponse(Result<[MarketplaceListing], Error>)
        
        // Search and filters
        case searchQueryChanged(String)
        case categorySelected(ListingCategory?)
        case stateSelected(NigerianState?)
        case toggleDiasporaFriendly
        
        // Favorites
        case toggleFavorite(ListingID)
        case favoriteToggled(Result<Bool, Error>)
        case loadFavorites
        case favoritesResponse(Result<[MarketplaceListing], Error>)
        
        // Navigation
        case listingTapped(ListingID)
        
        // Error
        case clearError
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.marketplaceClient) var client
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                
            case .loadListings:
                state.isLoading = true
                
                let category = state.selectedCategory
                let nigState = state.selectedState
                let diaspora = state.showDiasporaFriendlyOnly
                let query = state.searchQuery.isEmpty ? nil : state.searchQuery
                
                return .run { send in
                    await send(.listingsResponse(
                        Result {
                            try await client.getListings(
                                20, 0, category, nigState, nil, nil, query, diaspora
                            )
                        }
                    ))
                }
                
            case let .listingsResponse(.success(listings)):
                state.isLoading = false
                state.listings = IdentifiedArray(uniqueElements: listings)
                return .none
                
            case let .listingsResponse(.failure(error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none
                
            case .loadMoreListings:
                guard !state.isLoadingMore else { return .none }
                state.isLoadingMore = true
                
                let offset = state.listings.count
                let category = state.selectedCategory
                let nigState = state.selectedState
                let diaspora = state.showDiasporaFriendlyOnly
                
                return .run { send in
                    let newListings = try await client.getListings(
                        20, offset, category, nigState, nil, nil, nil, diaspora
                    )
                    await send(.listingsResponse(.success(newListings)))
                }
                
            case .loadFeatured:
                return .run { send in
                    await send(.featuredResponse(
                        Result { try await client.getFeatured(10) }
                    ))
                }
                
            case let .featuredResponse(.success(listings)):
                state.featuredListings = IdentifiedArray(uniqueElements: listings)
                return .none
                
            case let .featuredResponse(.failure(error)):
                state.error = error.localizedDescription
                return .none
                
            case let .searchQueryChanged(query):
                state.searchQuery = query
                return .send(.loadListings)
                    .debounce(id: SearchDebounceID(), for: 0.5, scheduler: DispatchQueue.main)
                
            case let .categorySelected(category):
                state.selectedCategory = category
                return .send(.loadListings)
                
            case let .stateSelected(nigState):
                state.selectedState = nigState
                return .send(.loadListings)
                
            case .toggleDiasporaFriendly:
                state.showDiasporaFriendlyOnly.toggle()
                return .send(.loadListings)
                
            case let .toggleFavorite(id):
                // Optimistically update
                if let index = state.listings.index(id: id) {
                    state.listings[index].isFavorite.toggle()
                }
                
                return .run { send in
                    await send(.favoriteToggled(
                        Result { try await client.toggleFavorite(id.rawValue.uuidString) }
                    ))
                }
                
            case .favoriteToggled:
                return .none
                
            case .loadFavorites:
                return .run { send in
                    await send(.favoritesResponse(
                        Result { try await client.getFavorites() }
                    ))
                }
                
            case let .favoritesResponse(.success(listings)):
                state.favorites = IdentifiedArray(uniqueElements: listings)
                return .none
                
            case let .favoritesResponse(.failure(error)):
                state.error = error.localizedDescription
                return .none
                
            case .listingTapped:
                return .none
                
            case .clearError:
                state.error = nil
                return .none
            }
        }
    }
    
    public init() {}
}

// MARK: - Search Debounce ID

private struct SearchDebounceID: Hashable {}
