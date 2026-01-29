package com.billyrinks.antimasking.domain.repository

import com.billyrinks.antimasking.domain.model.*
import kotlinx.coroutines.flow.Flow

/**
 * Repository interface for marketplace operations
 */
interface MarketplaceRepository {

    /**
     * Get listings with filters
     */
    suspend fun getListings(
        limit: Int = 20,
        offset: Int = 0,
        category: ListingCategory? = null,
        state: NigerianState? = null,
        minPrice: Double? = null,
        maxPrice: Double? = null,
        searchQuery: String? = null,
        diasporaFriendlyOnly: Boolean = false
    ): Result<List<MarketplaceListing>>

    /**
     * Get listing by ID
     */
    suspend fun getListingById(id: String): Result<MarketplaceListing>

    /**
     * Get featured listings
     */
    suspend fun getFeaturedListings(limit: Int = 10): Result<List<MarketplaceListing>>

    /**
     * Get listings by category
     */
    suspend fun getListingsByCategory(
        category: ListingCategory,
        limit: Int = 20
    ): Result<List<MarketplaceListing>>

    /**
     * Search listings
     */
    suspend fun searchListings(
        query: String,
        limit: Int = 20
    ): Result<List<MarketplaceListing>>

    /**
     * Toggle favorite status
     */
    suspend fun toggleFavorite(listingId: String): Result<Boolean>

    /**
     * Get user's favorite listings
     */
    suspend fun getFavorites(): Result<List<MarketplaceListing>>

    /**
     * Subscribe to new listings
     */
    fun observeNewListings(): Flow<MarketplaceListing>
}
