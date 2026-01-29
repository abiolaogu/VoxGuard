package com.billyrinks.antimasking.data.repository

import com.apollographql.apollo3.ApolloClient
import com.billyrinks.antimasking.di.IoDispatcher
import com.billyrinks.antimasking.domain.model.*
import com.billyrinks.antimasking.domain.repository.MarketplaceRepository
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.withContext
import java.math.BigDecimal
import java.time.Instant
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Implementation of MarketplaceRepository
 */
@Singleton
class MarketplaceRepositoryImpl @Inject constructor(
    private val apolloClient: ApolloClient,
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher
) : MarketplaceRepository {

    override suspend fun getListings(
        limit: Int,
        offset: Int,
        category: ListingCategory?,
        state: NigerianState?,
        minPrice: Double?,
        maxPrice: Double?,
        searchQuery: String?,
        diasporaFriendlyOnly: Boolean
    ): Result<List<MarketplaceListing>> = withContext(ioDispatcher) {
        try {
            delay(600)
            
            val listings = generateMockListings(limit, category, state, diasporaFriendlyOnly)
            Result.success(listings)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getListingById(id: String): Result<MarketplaceListing> =
        withContext(ioDispatcher) {
            try {
                delay(300)
                Result.success(generateMockListing(id))
            } catch (e: Exception) {
                Result.failure(e)
            }
        }

    override suspend fun getFeaturedListings(limit: Int): Result<List<MarketplaceListing>> =
        withContext(ioDispatcher) {
            try {
                delay(400)
                Result.success(
                    generateMockListings(limit, null, null, false).map {
                        it.copy(isDiasporaFriendly = true)
                    }
                )
            } catch (e: Exception) {
                Result.failure(e)
            }
        }

    override suspend fun getListingsByCategory(
        category: ListingCategory,
        limit: Int
    ): Result<List<MarketplaceListing>> = withContext(ioDispatcher) {
        try {
            delay(500)
            Result.success(generateMockListings(limit, category, null, false))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun searchListings(
        query: String,
        limit: Int
    ): Result<List<MarketplaceListing>> = withContext(ioDispatcher) {
        try {
            delay(700)
            val listings = generateMockListings(limit, null, null, false).filter {
                it.title.contains(query, ignoreCase = true) ||
                        it.description.contains(query, ignoreCase = true)
            }
            Result.success(listings)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun toggleFavorite(listingId: String): Result<Boolean> =
        withContext(ioDispatcher) {
            try {
                delay(300)
                Result.success(true) // Returns new favorite state
            } catch (e: Exception) {
                Result.failure(e)
            }
        }

    override suspend fun getFavorites(): Result<List<MarketplaceListing>> =
        withContext(ioDispatcher) {
            try {
                delay(400)
                Result.success(
                    generateMockListings(5, null, null, false).map {
                        it.copy(isFavorite = true)
                    }
                )
            } catch (e: Exception) {
                Result.failure(e)
            }
        }

    override fun observeNewListings(): Flow<MarketplaceListing> = flow {
        while (true) {
            delay(45000) // Every 45 seconds
            emit(generateMockListing(UUID.randomUUID().toString()))
        }
    }.flowOn(ioDispatcher)

    // =========================================================================
    // Mock Data Generation
    // =========================================================================

    private fun generateMockListings(
        count: Int,
        category: ListingCategory?,
        state: NigerianState?,
        diasporaFriendlyOnly: Boolean
    ): List<MarketplaceListing> {
        return (1..count).map { index ->
            val cat = category ?: ListingCategory.entries.random()
            val st = state ?: NigerianState.entries.random()
            
            MarketplaceListing(
                id = UUID.randomUUID().toString(),
                title = generateTitle(cat, index),
                description = generateDescription(cat),
                price = BigDecimal((10000..5000000).random()),
                currency = Currency.NGN,
                category = cat,
                images = listOf(
                    "https://picsum.photos/400/300?random=$index"
                ),
                thumbnailUrl = "https://picsum.photos/200/150?random=$index",
                sellerId = "seller-$index",
                sellerName = listOf("Emeka Stores", "Aisha Electronics", "Lagos Traders").random(),
                state = st,
                lga = "${st.displayName} Central",
                isDiasporaFriendly = diasporaFriendlyOnly || (index % 3 == 0),
                isNegotiable = index % 2 == 0,
                viewCount = (50..5000).random(),
                isFavorite = index % 4 == 0,
                status = ListingStatus.ACTIVE,
                createdAt = Instant.now().minusSeconds((index * 3600).toLong()),
                updatedAt = Instant.now()
            )
        }
    }

    private fun generateMockListing(id: String): MarketplaceListing {
        val category = ListingCategory.entries.random()
        return MarketplaceListing(
            id = id,
            title = generateTitle(category, 1),
            description = generateDescription(category),
            price = BigDecimal((50000..2000000).random()),
            currency = Currency.NGN,
            category = category,
            images = (1..5).map { "https://picsum.photos/400/300?random=$it" },
            thumbnailUrl = "https://picsum.photos/200/150?random=1",
            sellerId = "seller-1",
            sellerName = "Premium Seller",
            state = NigerianState.LAGOS,
            lga = "Ikeja",
            isDiasporaFriendly = true,
            isNegotiable = true,
            viewCount = 1234,
            isFavorite = false,
            status = ListingStatus.ACTIVE,
            createdAt = Instant.now().minusSeconds(86400),
            updatedAt = Instant.now()
        )
    }

    private fun generateTitle(category: ListingCategory, index: Int): String {
        return when (category) {
            ListingCategory.ELECTRONICS -> listOf(
                "iPhone 15 Pro Max 256GB",
                "Samsung Galaxy S24 Ultra",
                "MacBook Pro M3 14\"",
                "Sony PS5 Digital Edition"
            ).random()
            ListingCategory.VEHICLES -> listOf(
                "Toyota Camry 2022",
                "Honda Accord 2021",
                "Mercedes Benz C300 2023",
                "Toyota Highlander 2020"
            ).random()
            ListingCategory.PROPERTY -> listOf(
                "3 Bedroom Flat in Lekki",
                "Duplex for Sale in Ikoyi",
                "Land for Sale - 2 Plots",
                "Office Space in Victoria Island"
            ).random()
            ListingCategory.FASHION -> listOf(
                "Designer Ankara Collection",
                "Genuine Leather Shoes",
                "Premium Agbada Set",
                "Italian Suits Collection"
            ).random()
            else -> "${category.displayName} Item #$index"
        }
    }

    private fun generateDescription(category: ListingCategory): String {
        return when (category) {
            ListingCategory.ELECTRONICS -> "Brand new, sealed in box. Comes with original warranty. Lagos delivery available."
            ListingCategory.VEHICLES -> "Well maintained, full service history. All documents intact. Serious buyers only."
            ListingCategory.PROPERTY -> "Prime location, excellent infrastructure. C of O available. Negotiable for diaspora buyers."
            ListingCategory.FASHION -> "100% authentic. Various sizes available. Nationwide delivery."
            else -> "Quality product available for immediate purchase. Contact for more details."
        }
    }
}
