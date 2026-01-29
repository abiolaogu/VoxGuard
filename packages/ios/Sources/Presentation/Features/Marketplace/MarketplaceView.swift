import ComposableArchitecture
import SwiftUI

// MARK: - Marketplace View

public struct MarketplaceView: View {
    @Bindable var store: StoreOf<MarketplaceFeature>
    
    public init(store: StoreOf<MarketplaceFeature>) {
        self.store = store
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Search Bar
                    searchBar
                    
                    // Categories
                    categoriesSection
                    
                    // Diaspora Filter
                    diasporaFilterChip
                    
                    // Featured Section
                    if !store.featuredListings.isEmpty {
                        featuredSection
                    }
                    
                    // Listings Grid
                    listingsGrid
                }
                .padding()
            }
            .navigationTitle("Marketplace 🇳🇬")
            .task {
                await store.send(.loadListings).finish()
                await store.send(.loadFeatured).finish()
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search products...", text: $store.searchQuery.sending(\.searchQueryChanged))
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Categories Section
    
    private var categoriesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryChip(
                    title: "All",
                    icon: "square.grid.2x2",
                    isSelected: store.selectedCategory == nil
                ) {
                    store.send(.categorySelected(nil))
                }
                
                ForEach([ListingCategory.electronics, .vehicles, .property, .fashion, .agriculture], id: \.self) { category in
                    CategoryChip(
                        title: category.displayName,
                        icon: category.iconName,
                        isSelected: store.selectedCategory == category
                    ) {
                        store.send(.categorySelected(category))
                    }
                }
            }
        }
    }
    
    // MARK: - Diaspora Filter
    
    private var diasporaFilterChip: some View {
        HStack {
            Toggle(isOn: $store.showDiasporaFriendlyOnly.sending(\.toggleDiasporaFriendly)) {
                HStack {
                    Text("🇳🇬")
                    Text("Diaspora Friendly Only")
                        .font(.subheadline)
                }
            }
            .toggleStyle(.button)
            .buttonStyle(.bordered)
            .tint(store.showDiasporaFriendlyOnly ? .green : .gray)
            
            Spacer()
        }
    }
    
    // MARK: - Featured Section
    
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(store.featuredListings) { listing in
                        FeaturedListingCard(listing: listing) {
                            store.send(.listingTapped(listing.id))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Listings Grid
    
    private var listingsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Products")
                .font(.headline)
            
            if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if store.listings.isEmpty {
                ContentUnavailableView(
                    "No Products Found",
                    systemImage: "storefront",
                    description: Text("Try adjusting your filters")
                )
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(store.listings) { listing in
                        ListingCard(listing: listing) {
                            store.send(.listingTapped(listing.id))
                        } onFavorite: {
                            store.send(.toggleFavorite(listing.id))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Featured Listing Card

struct FeaturedListingCard: View {
    let listing: MarketplaceListing
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading) {
                // Image placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 200, height: 120)
                    .overlay {
                        Image(systemName: listing.category.iconName)
                            .font(.largeTitle)
                            .foregroundStyle(Color.accentColor)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text("\(listing.currency.symbol)\(listing.price, format: .number)")
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)
                    
                    if listing.isDiasporaFriendly {
                        HStack(spacing: 4) {
                            Text("🇳🇬")
                            Text("Diaspora Friendly")
                                .font(.caption2)
                        }
                        .foregroundStyle(.green)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .frame(width: 200)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Listing Card

struct ListingCard: View {
    let listing: MarketplaceListing
    let onTap: () -> Void
    let onFavorite: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Image
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor.opacity(0.1))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            Image(systemName: listing.category.iconName)
                                .font(.title)
                                .foregroundStyle(Color.accentColor)
                        }
                    
                    Button(action: onFavorite) {
                        Image(systemName: listing.isFavorite ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundStyle(listing.isFavorite ? .red : .secondary)
                            .padding(8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                    
                    Text("\(listing.currency.symbol)\(listing.price, format: .number)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.accentColor)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.caption2)
                        Text(listing.state.displayName)
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding(8)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    MarketplaceView(
        store: Store(initialState: MarketplaceFeature.State()) {
            MarketplaceFeature()
        }
    )
}
