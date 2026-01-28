/**
 * Remittance Domain - Supporting Bounded Context
 * 
 * Nigerian remittance and cross-border transfers.
 */

// ============================================================================
// Value Objects
// ============================================================================

/**
 * Money value object with currency
 */
export interface Money {
    readonly amount: number;
    readonly currency: Currency;
    readonly formatted: string;
}

export type Currency = 'NGN' | 'USD' | 'GBP' | 'EUR' | 'CAD';

/**
 * Exchange rate snapshot
 */
export interface ExchangeRate {
    readonly source: Currency;
    readonly target: Currency;
    readonly rate: number;
    readonly timestamp: Date;
    readonly provider: string;
}

/**
 * Bank account identifier
 */
export interface BankAccount {
    readonly bankCode: string;
    readonly bankName: string;
    readonly accountNumber: string;
    readonly accountName: string;
    readonly isVerified: boolean;
}

/**
 * Nigerian bank codes
 */
export const NIGERIAN_BANKS: Record<string, string> = {
    '044': 'Access Bank',
    '023': 'Citibank Nigeria',
    '050': 'Ecobank Nigeria',
    '070': 'Fidelity Bank',
    '011': 'First Bank of Nigeria',
    '214': 'First City Monument Bank',
    '058': 'Guaranty Trust Bank',
    '030': 'Heritage Bank',
    '301': 'Jaiz Bank',
    '082': 'Keystone Bank',
    '526': 'Parallex Bank',
    '076': 'Polaris Bank',
    '101': 'Providus Bank',
    '221': 'Stanbic IBTC Bank',
    '068': 'Standard Chartered',
    '232': 'Sterling Bank',
    '100': 'SunTrust Bank',
    '032': 'Union Bank of Nigeria',
    '033': 'United Bank for Africa',
    '215': 'Unity Bank',
    '035': 'Wema Bank',
    '057': 'Zenith Bank',
};

// ============================================================================
// Entities
// ============================================================================

/**
 * Remittance transfer entity
 */
export interface Transfer {
    readonly id: string;
    readonly senderId: string;
    readonly recipientId: string;
    readonly sourceAmount: Money;
    readonly targetAmount: Money;
    readonly exchangeRate: ExchangeRate;
    readonly fee: Money;
    readonly status: TransferStatus;
    readonly purpose: TransferPurpose;
    readonly recipientAccount: BankAccount;
    readonly reference: string;
    readonly narration?: string;
    readonly createdAt: Date;
    readonly processedAt?: Date;
    readonly completedAt?: Date;
    readonly failedAt?: Date;
    readonly failureReason?: string;
}

export type TransferStatus =
    | 'PENDING'
    | 'PROCESSING'
    | 'COMPLETED'
    | 'FAILED'
    | 'REFUNDED'
    | 'CANCELLED';

export type TransferPurpose =
    | 'FAMILY_SUPPORT'
    | 'EDUCATION'
    | 'MEDICAL'
    | 'INVESTMENT'
    | 'BUSINESS'
    | 'OTHER';

/**
 * Beneficiary entity
 */
export interface Beneficiary {
    readonly id: string;
    readonly userId: string;
    readonly name: string;
    readonly relationship: string;
    readonly bankAccount: BankAccount;
    readonly phoneNumber?: string;
    readonly email?: string;
    readonly isActive: boolean;
    readonly createdAt: Date;
}

// ============================================================================
// Domain Events
// ============================================================================

export interface TransferInitiatedEvent {
    readonly eventType: 'TransferInitiated';
    readonly transferId: string;
    readonly senderId: string;
    readonly amount: Money;
    readonly targetCurrency: Currency;
}

export interface TransferCompletedEvent {
    readonly eventType: 'TransferCompleted';
    readonly transferId: string;
    readonly recipientAccount: BankAccount;
    readonly completedAt: Date;
}

export interface TransferFailedEvent {
    readonly eventType: 'TransferFailed';
    readonly transferId: string;
    readonly reason: string;
    readonly failedAt: Date;
}

// ============================================================================
// Repository Interfaces
// ============================================================================

export interface TransferRepository {
    save(transfer: Transfer): Promise<void>;
    findById(id: string): Promise<Transfer | null>;
    findBySender(senderId: string): Promise<Transfer[]>;
    findByStatus(status: TransferStatus): Promise<Transfer[]>;
    findPendingOlderThan(minutes: number): Promise<Transfer[]>;
}

export interface BeneficiaryRepository {
    save(beneficiary: Beneficiary): Promise<void>;
    findById(id: string): Promise<Beneficiary | null>;
    findByUser(userId: string): Promise<Beneficiary[]>;
    findByAccountNumber(accountNumber: string): Promise<Beneficiary | null>;
}
