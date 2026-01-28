/**
 * Identity Domain - Generic Bounded Context
 * 
 * User authentication, authorization, and KYC.
 */

// ============================================================================
// Value Objects
// ============================================================================

/**
 * Email address value object
 */
export interface Email {
    readonly value: string;
    readonly isVerified: boolean;
    readonly domain: string;
}

/**
 * Phone number value object
 */
export interface PhoneNumber {
    readonly value: string;
    readonly countryCode: string;
    readonly nationalNumber: string;
    readonly isVerified: boolean;
}

/**
 * National identification
 */
export interface NationalId {
    readonly type: IdType;
    readonly number: string;
    readonly issuedAt?: Date;
    readonly expiresAt?: Date;
    readonly isVerified: boolean;
}

export type IdType =
    | 'NIN'                    // National Identification Number
    | 'BVN'                    // Bank Verification Number
    | 'PASSPORT'
    | 'DRIVERS_LICENSE'
    | 'VOTERS_CARD';

// ============================================================================
// Entities
// ============================================================================

/**
 * User entity
 */
export interface User {
    readonly id: string;
    readonly email: Email;
    readonly phone?: PhoneNumber;
    readonly firstName: string;
    readonly lastName: string;
    readonly middleName?: string;
    readonly dateOfBirth?: Date;
    readonly gender?: Gender;
    readonly role: UserRole;
    readonly status: UserStatus;
    readonly kycLevel: KYCLevel;
    readonly preferences: UserPreferences;
    readonly createdAt: Date;
    readonly updatedAt: Date;
    readonly lastLoginAt?: Date;
}

export type Gender = 'MALE' | 'FEMALE' | 'OTHER';

export type UserRole =
    | 'USER'
    | 'PROVIDER'
    | 'ANALYST'
    | 'ADMIN'
    | 'SUPER_ADMIN';

export type UserStatus =
    | 'PENDING'
    | 'ACTIVE'
    | 'SUSPENDED'
    | 'DEACTIVATED';

export type KYCLevel =
    | 'NONE'           // No verification
    | 'BASIC'          // Email/phone verified
    | 'INTERMEDIATE'   // ID verified
    | 'FULL';          // Full verification + address

export interface UserPreferences {
    readonly language: string;
    readonly timezone: string;
    readonly notifications: NotificationSettings;
}

export interface NotificationSettings {
    readonly email: boolean;
    readonly push: boolean;
    readonly sms: boolean;
}

/**
 * KYC verification entity
 */
export interface KYCVerification {
    readonly id: string;
    readonly userId: string;
    readonly level: KYCLevel;
    readonly documents: KYCDocument[];
    readonly status: VerificationStatus;
    readonly submittedAt: Date;
    readonly reviewedAt?: Date;
    readonly reviewedBy?: string;
    readonly rejectionReason?: string;
    readonly expiresAt?: Date;
}

export interface KYCDocument {
    readonly type: IdType;
    readonly documentUrl: string;
    readonly selfieUrl?: string;
    readonly status: VerificationStatus;
    readonly extractedData?: Record<string, string>;
}

export type VerificationStatus =
    | 'PENDING'
    | 'IN_REVIEW'
    | 'APPROVED'
    | 'REJECTED'
    | 'EXPIRED';

/**
 * Authentication session
 */
export interface Session {
    readonly id: string;
    readonly userId: string;
    readonly deviceId: string;
    readonly deviceInfo: DeviceInfo;
    readonly ipAddress: string;
    readonly isActive: boolean;
    readonly createdAt: Date;
    readonly expiresAt: Date;
    readonly lastActivityAt: Date;
}

export interface DeviceInfo {
    readonly platform: 'WEB' | 'ANDROID' | 'IOS';
    readonly browser?: string;
    readonly os?: string;
    readonly appVersion?: string;
}

// ============================================================================
// Domain Events
// ============================================================================

export interface UserRegisteredEvent {
    readonly eventType: 'UserRegistered';
    readonly userId: string;
    readonly email: string;
    readonly role: UserRole;
}

export interface EmailVerifiedEvent {
    readonly eventType: 'EmailVerified';
    readonly userId: string;
    readonly email: string;
    readonly verifiedAt: Date;
}

export interface KYCSubmittedEvent {
    readonly eventType: 'KYCSubmitted';
    readonly userId: string;
    readonly level: KYCLevel;
    readonly documentTypes: IdType[];
}

export interface KYCApprovedEvent {
    readonly eventType: 'KYCApproved';
    readonly userId: string;
    readonly level: KYCLevel;
    readonly approvedBy: string;
}

export interface KYCRejectedEvent {
    readonly eventType: 'KYCRejected';
    readonly userId: string;
    readonly level: KYCLevel;
    readonly reason: string;
}

export interface UserSuspendedEvent {
    readonly eventType: 'UserSuspended';
    readonly userId: string;
    readonly reason: string;
    readonly suspendedBy: string;
}

// ============================================================================
// Repository Interfaces
// ============================================================================

export interface UserRepository {
    save(user: User): Promise<void>;
    findById(id: string): Promise<User | null>;
    findByEmail(email: string): Promise<User | null>;
    findByPhone(phone: string): Promise<User | null>;
    findByRole(role: UserRole): Promise<User[]>;
}

export interface KYCRepository {
    save(verification: KYCVerification): Promise<void>;
    findById(id: string): Promise<KYCVerification | null>;
    findByUser(userId: string): Promise<KYCVerification[]>;
    findPending(): Promise<KYCVerification[]>;
}

export interface SessionRepository {
    save(session: Session): Promise<void>;
    findById(id: string): Promise<Session | null>;
    findByUser(userId: string): Promise<Session[]>;
    findActiveByUser(userId: string): Promise<Session[]>;
    invalidateAll(userId: string): Promise<void>;
}
