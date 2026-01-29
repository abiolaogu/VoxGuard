import Foundation
import Tagged

// MARK: - Marketplace Listing

public typealias ListingID = Tagged<MarketplaceListing, UUID>

public struct MarketplaceListing: Equatable, Identifiable, Sendable {
    public let id: ListingID
    public let title: String
    public let description: String
    public let price: Decimal
    public let currency: Currency
    public let category: ListingCategory
    public let images: [URL]
    public let thumbnailURL: URL?
    public let sellerId: String
    public let sellerName: String
    public let state: NigerianState
    public let lga: String?
    public let isDiasporaFriendly: Bool
    public let isNegotiable: Bool
    public let viewCount: Int
    public var isFavorite: Bool
    public let status: ListingStatus
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        id: ListingID,
        title: String,
        description: String,
        price: Decimal,
        currency: Currency = .ngn,
        category: ListingCategory,
        images: [URL] = [],
        thumbnailURL: URL? = nil,
        sellerId: String,
        sellerName: String,
        state: NigerianState,
        lga: String? = nil,
        isDiasporaFriendly: Bool = false,
        isNegotiable: Bool = false,
        viewCount: Int = 0,
        isFavorite: Bool = false,
        status: ListingStatus = .active,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.price = price
        self.currency = currency
        self.category = category
        self.images = images
        self.thumbnailURL = thumbnailURL
        self.sellerId = sellerId
        self.sellerName = sellerName
        self.state = state
        self.lga = lga
        self.isDiasporaFriendly = isDiasporaFriendly
        self.isNegotiable = isNegotiable
        self.viewCount = viewCount
        self.isFavorite = isFavorite
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum ListingCategory: String, Equatable, Sendable, CaseIterable {
    case electronics = "ELECTRONICS"
    case vehicles = "VEHICLES"
    case property = "PROPERTY"
    case fashion = "FASHION"
    case agriculture = "AGRICULTURE"
    case services = "SERVICES"
    case food = "FOOD"
    case health = "HEALTH"
    case furniture = "FURNITURE"
    case jobs = "JOBS"
    case other = "OTHER"
    
    public var displayName: String {
        switch self {
        case .electronics: return "Electronics"
        case .vehicles: return "Vehicles"
        case .property: return "Property"
        case .fashion: return "Fashion"
        case .agriculture: return "Agriculture"
        case .services: return "Services"
        case .food: return "Food & Beverages"
        case .health: return "Health & Beauty"
        case .furniture: return "Furniture"
        case .jobs: return "Jobs"
        case .other: return "Other"
        }
    }
    
    public var emoji: String {
        switch self {
        case .electronics: return "📱"
        case .vehicles: return "🚗"
        case .property: return "🏠"
        case .fashion: return "👗"
        case .agriculture: return "🌾"
        case .services: return "🛠️"
        case .food: return "🍲"
        case .health: return "💄"
        case .furniture: return "🪑"
        case .jobs: return "💼"
        case .other: return "📦"
        }
    }
    
    public var iconName: String {
        switch self {
        case .electronics: return "iphone"
        case .vehicles: return "car.fill"
        case .property: return "house.fill"
        case .fashion: return "tshirt.fill"
        case .agriculture: return "leaf.fill"
        case .services: return "wrench.fill"
        case .food: return "fork.knife"
        case .health: return "heart.fill"
        case .furniture: return "sofa.fill"
        case .jobs: return "briefcase.fill"
        case .other: return "shippingbox.fill"
        }
    }
}

public enum ListingStatus: String, Equatable, Sendable, CaseIterable {
    case active = "ACTIVE"
    case sold = "SOLD"
    case reserved = "RESERVED"
    case expired = "EXPIRED"
    case deleted = "DELETED"
}
