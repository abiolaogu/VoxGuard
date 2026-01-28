/**
 * Marketplace Domain - Supporting Bounded Context
 * 
 * Supply/demand matching for diaspora services.
 */

// ============================================================================
// Value Objects
// ============================================================================

/**
 * Location value object
 */
export interface Location {
    readonly country: string;
    readonly state?: string;
    readonly city?: string;
    readonly coordinates?: {
        readonly latitude: number;
        readonly longitude: number;
    };
}

/**
 * Price range
 */
export interface PriceRange {
    readonly min: number;
    readonly max: number;
    readonly currency: string;
}

/**
 * Rating value object
 */
export interface Rating {
    readonly score: number;         // 1-5
    readonly count: number;
    readonly average: number;
}

// ============================================================================
// Entities
// ============================================================================

/**
 * Service listing entity
 */
export interface ServiceListing {
    readonly id: string;
    readonly providerId: string;
    readonly category: ServiceCategory;
    readonly title: string;
    readonly description: string;
    readonly priceRange: PriceRange;
    readonly location: Location;
    readonly availability: Availability;
    readonly rating: Rating;
    readonly tags: string[];
    readonly images: string[];
    readonly isActive: boolean;
    readonly isFeatured: boolean;
    readonly createdAt: Date;
    readonly updatedAt: Date;
}

export type ServiceCategory =
    | 'PROPERTY_MANAGEMENT'
    | 'LEGAL_SERVICES'
    | 'FINANCIAL_SERVICES'
    | 'LOGISTICS'
    | 'HEALTHCARE'
    | 'EDUCATION'
    | 'CONSTRUCTION'
    | 'AUTOMOTIVE'
    | 'OTHER';

export type Availability =
    | 'IMMEDIATE'
    | 'SCHEDULED'
    | 'ON_REQUEST';

/**
 * Service request entity
 */
export interface ServiceRequest {
    readonly id: string;
    readonly requesterId: string;
    readonly category: ServiceCategory;
    readonly title: string;
    readonly description: string;
    readonly budget: PriceRange;
    readonly location: Location;
    readonly urgency: Urgency;
    readonly status: RequestStatus;
    readonly matchedListings: string[];
    readonly selectedProvider?: string;
    readonly createdAt: Date;
    readonly expiresAt: Date;
}

export type Urgency = 'LOW' | 'MEDIUM' | 'HIGH' | 'URGENT';

export type RequestStatus =
    | 'OPEN'
    | 'MATCHED'
    | 'IN_PROGRESS'
    | 'COMPLETED'
    | 'CANCELLED'
    | 'EXPIRED';

/**
 * Service provider profile
 */
export interface ProviderProfile {
    readonly id: string;
    readonly userId: string;
    readonly businessName: string;
    readonly businessType: string;
    readonly description: string;
    readonly location: Location;
    readonly categories: ServiceCategory[];
    readonly rating: Rating;
    readonly isVerified: boolean;
    readonly verifiedAt?: Date;
    readonly documents: VerificationDocument[];
    readonly createdAt: Date;
}

export interface VerificationDocument {
    readonly type: 'CAC' | 'TIN' | 'ID' | 'LICENSE';
    readonly documentId: string;
    readonly status: 'PENDING' | 'VERIFIED' | 'REJECTED';
    readonly verifiedAt?: Date;
}

// ============================================================================
// Domain Events
// ============================================================================

export interface ListingCreatedEvent {
    readonly eventType: 'ListingCreated';
    readonly listingId: string;
    readonly providerId: string;
    readonly category: ServiceCategory;
}

export interface RequestMatchedEvent {
    readonly eventType: 'RequestMatched';
    readonly requestId: string;
    readonly matchedListings: string[];
    readonly matchScore: number;
}

export interface ServiceCompletedEvent {
    readonly eventType: 'ServiceCompleted';
    readonly requestId: string;
    readonly providerId: string;
    readonly rating?: number;
}

// ============================================================================
// Repository Interfaces
// ============================================================================

export interface ListingRepository {
    save(listing: ServiceListing): Promise<void>;
    findById(id: string): Promise<ServiceListing | null>;
    findByProvider(providerId: string): Promise<ServiceListing[]>;
    findByCategory(category: ServiceCategory): Promise<ServiceListing[]>;
    searchByLocation(location: Location, radiusKm: number): Promise<ServiceListing[]>;
}

export interface RequestRepository {
    save(request: ServiceRequest): Promise<void>;
    findById(id: string): Promise<ServiceRequest | null>;
    findByRequester(requesterId: string): Promise<ServiceRequest[]>;
    findOpenByCategory(category: ServiceCategory): Promise<ServiceRequest[]>;
}
