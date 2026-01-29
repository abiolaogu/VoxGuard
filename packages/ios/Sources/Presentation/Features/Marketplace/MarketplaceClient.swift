import Dependencies
import Foundation

// MARK: - Marketplace Client

public struct MarketplaceClient: Sendable {
    public var getListings: @Sendable (Int, Int, ListingCategory?, NigerianState?, Double?, Double?, String?, Bool) async throws -> [MarketplaceListing]
    public var getListing: @Sendable (String) async throws -> MarketplaceListing
    public var getFeatured: @Sendable (Int) async throws -> [MarketplaceListing]
    public var search: @Sendable (String, Int) async throws -> [MarketplaceListing]
    public var toggleFavorite: @Sendable (String) async throws -> Bool
    public var getFavorites: @Sendable () async throws -> [MarketplaceListing]
    
    public init(
        getListings: @escaping @Sendable (Int, Int, ListingCategory?, NigerianState?, Double?, Double?, String?, Bool) async throws -> [MarketplaceListing],
        getListing: @escaping @Sendable (String) async throws -> MarketplaceListing,
        getFeatured: @escaping @Sendable (Int) async throws -> [MarketplaceListing],
        search: @escaping @Sendable (String, Int) async throws -> [MarketplaceListing],
        toggleFavorite: @escaping @Sendable (String) async throws -> Bool,
        getFavorites: @escaping @Sendable () async throws -> [MarketplaceListing]
    ) {
        self.getListings = getListings
        self.getListing = getListing
        self.getFeatured = getFeatured
        self.search = search
        self.toggleFavorite = toggleFavorite
        self.getFavorites = getFavorites
    }
}

extension MarketplaceClient: DependencyKey {
    public static var liveValue: MarketplaceClient {
        MarketplaceClient(
            getListings: { limit, offset, category, state, minPrice, maxPrice, query, diaspora in
                try await Task.sleep(nanoseconds: 600_000_000)
                
                return (0..<limit).map { index in
                    let cat = category ?? ListingCategory.allCases.randomElement()!
                    let st = state ?? NigerianState.allCases.randomElement()!
                    
                    return MarketplaceListing(
                        id: .init(rawValue: UUID()),
                        title: generateTitle(for: cat, index: index),
                        description: "Quality product available for immediate purchase.",
                        price: Decimal(Int.random(in: 10000...5000000)),
                        currency: .ngn,
                        category: cat,
                        images: [],
                        thumbnailURL: URL(string: "https://picsum.photos/200/150?random=\(index)"),
                        sellerId: "seller-\(index)",
                        sellerName: ["Emeka Stores", "Aisha Electronics", "Lagos Traders"].randomElement()!,
                        state: st,
                        lga: "\(st.displayName) Central",
                        isDiasporaFriendly: diaspora || (index % 3 == 0),
                        isNegotiable: index % 2 == 0,
                        viewCount: Int.random(in: 50...5000),
                        isFavorite: index % 4 == 0,
                        status: .active,
                        createdAt: Date().addingTimeInterval(TimeInterval(-index * 3600)),
                        updatedAt: Date()
                    )
                }
            },
            getListing: { id in
                try await Task.sleep(nanoseconds: 300_000_000)
                
                return MarketplaceListing(
                    id: .init(rawValue: UUID(uuidString: id) ?? UUID()),
                    title: "iPhone 15 Pro Max 256GB",
                    description: "Brand new, sealed in box. Comes with original warranty.",
                    price: 1500000,
                    currency: .ngn,
                    category: .electronics,
                    images: [],
                    sellerId: "seller-1",
                    sellerName: "Premium Seller",
                    state: .lagos,
                    lga: "Ikeja",
                    isDiasporaFriendly: true,
                    isNegotiable: true,
                    viewCount: 1234,
                    status: .active
                )
            },
            getFeatured: { limit in
                try await Task.sleep(nanoseconds: 400_000_000)
                
                return (0..<limit).map { index in
                    MarketplaceListing(
                        id: .init(rawValue: UUID()),
                        title: ["Premium Land in Lekki", "Toyota Camry 2023", "MacBook Pro M3"].randomElement()!,
                        description: "Featured listing",
                        price: Decimal(Int.random(in: 500000...10000000)),
                        currency: .ngn,
                        category: [.property, .vehicles, .electronics].randomElement()!,
                        images: [],
                        sellerId: "seller-\(index)",
                        sellerName: "Verified Seller",
                        state: .lagos,
                        isDiasporaFriendly: true,
                        viewCount: Int.random(in: 1000...10000),
                        status: .active
                    )
                }
            },
            search: { query, limit in
                try await Task.sleep(nanoseconds: 700_000_000)
                return []
            },
            toggleFavorite: { _ in
                try await Task.sleep(nanoseconds: 300_000_000)
                return true
            },
            getFavorites: {
                try await Task.sleep(nanoseconds: 400_000_000)
                return []
            }
        )
    }
    
    public static var testValue: MarketplaceClient {
        MarketplaceClient(
            getListings: { _, _, _, _, _, _, _, _ in [] },
            getListing: { _ in fatalError() },
            getFeatured: { _ in [] },
            search: { _, _ in [] },
            toggleFavorite: { _ in true },
            getFavorites: { [] }
        )
    }
}

private func generateTitle(for category: ListingCategory, index: Int) -> String {
    switch category {
    case .electronics: return ["iPhone 15 Pro Max", "Samsung Galaxy S24", "MacBook Pro M3", "Sony PS5"].randomElement()!
    case .vehicles: return ["Toyota Camry 2022", "Honda Accord 2021", "Mercedes C300 2023"].randomElement()!
    case .property: return ["3 Bedroom Flat in Lekki", "Duplex in Ikoyi", "Land for Sale"].randomElement()!
    case .fashion: return ["Designer Ankara", "Genuine Leather Shoes", "Premium Agbada"].randomElement()!
    default: return "\(category.displayName) Item #\(index)"
    }
}

extension DependencyValues {
    public var marketplaceClient: MarketplaceClient {
        get { self[MarketplaceClient.self] }
        set { self[MarketplaceClient.self] = newValue }
    }
}
