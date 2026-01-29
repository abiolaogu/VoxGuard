package com.billyrinks.antimasking.domain.model

import java.math.BigDecimal
import java.time.Instant

/**
 * Domain model for marketplace listing
 */
data class MarketplaceListing(
    val id: String,
    val title: String,
    val description: String,
    val price: BigDecimal,
    val currency: Currency = Currency.NGN,
    val category: ListingCategory,
    val images: List<String>,
    val thumbnailUrl: String?,
    val sellerId: String,
    val sellerName: String,
    val state: NigerianState,
    val lga: String? = null,
    val isDiasporaFriendly: Boolean = false,
    val isNegotiable: Boolean = false,
    val viewCount: Int = 0,
    val isFavorite: Boolean = false,
    val status: ListingStatus,
    val createdAt: Instant,
    val updatedAt: Instant
)

enum class ListingCategory(val displayName: String, val emoji: String) {
    ELECTRONICS("Electronics", "📱"),
    VEHICLES("Vehicles", "🚗"),
    PROPERTY("Property", "🏠"),
    FASHION("Fashion", "👗"),
    AGRICULTURE("Agriculture", "🌾"),
    SERVICES("Services", "🛠️"),
    FOOD("Food & Beverages", "🍲"),
    HEALTH("Health & Beauty", "💄"),
    FURNITURE("Furniture", "🪑"),
    JOBS("Jobs", "💼"),
    OTHER("Other", "📦")
}

enum class ListingStatus {
    ACTIVE,
    SOLD,
    RESERVED,
    EXPIRED,
    DELETED
}

/**
 * Nigerian states
 */
enum class NigerianState(val displayName: String, val region: GeopoliticalZone) {
    ABIA("Abia", GeopoliticalZone.SOUTH_EAST),
    ADAMAWA("Adamawa", GeopoliticalZone.NORTH_EAST),
    AKWA_IBOM("Akwa Ibom", GeopoliticalZone.SOUTH_SOUTH),
    ANAMBRA("Anambra", GeopoliticalZone.SOUTH_EAST),
    BAUCHI("Bauchi", GeopoliticalZone.NORTH_EAST),
    BAYELSA("Bayelsa", GeopoliticalZone.SOUTH_SOUTH),
    BENUE("Benue", GeopoliticalZone.NORTH_CENTRAL),
    BORNO("Borno", GeopoliticalZone.NORTH_EAST),
    CROSS_RIVER("Cross River", GeopoliticalZone.SOUTH_SOUTH),
    DELTA("Delta", GeopoliticalZone.SOUTH_SOUTH),
    EBONYI("Ebonyi", GeopoliticalZone.SOUTH_EAST),
    EDO("Edo", GeopoliticalZone.SOUTH_SOUTH),
    EKITI("Ekiti", GeopoliticalZone.SOUTH_WEST),
    ENUGU("Enugu", GeopoliticalZone.SOUTH_EAST),
    FCT("Federal Capital Territory", GeopoliticalZone.NORTH_CENTRAL),
    GOMBE("Gombe", GeopoliticalZone.NORTH_EAST),
    IMO("Imo", GeopoliticalZone.SOUTH_EAST),
    JIGAWA("Jigawa", GeopoliticalZone.NORTH_WEST),
    KADUNA("Kaduna", GeopoliticalZone.NORTH_WEST),
    KANO("Kano", GeopoliticalZone.NORTH_WEST),
    KATSINA("Katsina", GeopoliticalZone.NORTH_WEST),
    KEBBI("Kebbi", GeopoliticalZone.NORTH_WEST),
    KOGI("Kogi", GeopoliticalZone.NORTH_CENTRAL),
    KWARA("Kwara", GeopoliticalZone.NORTH_CENTRAL),
    LAGOS("Lagos", GeopoliticalZone.SOUTH_WEST),
    NASARAWA("Nasarawa", GeopoliticalZone.NORTH_CENTRAL),
    NIGER("Niger", GeopoliticalZone.NORTH_CENTRAL),
    OGUN("Ogun", GeopoliticalZone.SOUTH_WEST),
    ONDO("Ondo", GeopoliticalZone.SOUTH_WEST),
    OSUN("Osun", GeopoliticalZone.SOUTH_WEST),
    OYO("Oyo", GeopoliticalZone.SOUTH_WEST),
    PLATEAU("Plateau", GeopoliticalZone.NORTH_CENTRAL),
    RIVERS("Rivers", GeopoliticalZone.SOUTH_SOUTH),
    SOKOTO("Sokoto", GeopoliticalZone.NORTH_WEST),
    TARABA("Taraba", GeopoliticalZone.NORTH_EAST),
    YOBE("Yobe", GeopoliticalZone.NORTH_EAST),
    ZAMFARA("Zamfara", GeopoliticalZone.NORTH_WEST)
}

enum class GeopoliticalZone(val displayName: String) {
    NORTH_CENTRAL("North Central"),
    NORTH_EAST("North East"),
    NORTH_WEST("North West"),
    SOUTH_EAST("South East"),
    SOUTH_SOUTH("South South"),
    SOUTH_WEST("South West")
}
