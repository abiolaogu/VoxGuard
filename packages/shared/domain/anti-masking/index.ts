/**
 * Anti-Masking Domain - Core Bounded Context
 * 
 * This is the Core Domain for the Anti-Call Masking Platform.
 * Contains call verification, masking detection, and carrier integration.
 */

// ============================================================================
// Value Objects
// ============================================================================

/**
 * Nigerian MSISDN (Mobile Station International Subscriber Directory Number)
 */
export interface MSISDN {
    readonly value: string;
    readonly normalized: string;
    readonly prefix: string;
    readonly carrier: Carrier | null;
    readonly isNigerian: boolean;
}

/**
 * Nigerian mobile carriers
 */
export type Carrier = 'MTN' | 'GLO' | 'AIRTEL' | '9MOBILE';

/**
 * Nigerian carrier prefix mappings
 */
export const CARRIER_PREFIXES: Record<Carrier, string[]> = {
    MTN: ['0803', '0806', '0703', '0706', '0813', '0816', '0814', '0903', '0906'],
    GLO: ['0805', '0807', '0705', '0815', '0811', '0905'],
    AIRTEL: ['0802', '0808', '0708', '0812', '0701', '0902', '0901', '0907'],
    '9MOBILE': ['0809', '0818', '0817', '0909', '0908'],
};

/**
 * IP Address value object
 */
export interface IPAddress {
    readonly value: string;
    readonly isIPv4: boolean;
    readonly isIPv6: boolean;
    readonly isPrivate: boolean;
    readonly isLikelyInternational: boolean;
}

/**
 * Fraud confidence score (0.0 - 1.0)
 */
export interface FraudScore {
    readonly value: number;
    readonly severity: Severity;
    readonly exceedsBlockThreshold: boolean;
}

/**
 * Alert severity levels
 */
export type Severity = 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';

/**
 * Types of fraud detected
 */
export type FraudType =
    | 'CLI_MASKING'
    | 'SIMBOX'
    | 'WANGIRI'
    | 'IRSF'
    | 'PBX_HACKING';

// ============================================================================
// Entities
// ============================================================================

/**
 * Call entity - represents a single call in the detection system
 */
export interface Call {
    readonly id: string;
    readonly aNumber: MSISDN;           // Caller (A-number)
    readonly bNumber: MSISDN;           // Called party (B-number)
    readonly sourceIP: IPAddress;
    readonly timestamp: Date;
    readonly status: CallStatus;
    readonly switchId?: string;
    readonly rawCallId?: string;
    readonly isFlagged: boolean;
    readonly alertId?: string;
    readonly fraudScore: FraudScore;
    readonly createdAt: Date;
    readonly updatedAt: Date;
}

export type CallStatus = 'RINGING' | 'ACTIVE' | 'COMPLETED' | 'FAILED' | 'BLOCKED';

/**
 * Fraud Alert entity
 */
export interface FraudAlert {
    readonly id: string;
    readonly bNumber: MSISDN;
    readonly fraudType: FraudType;
    readonly score: FraudScore;
    readonly severity: Severity;
    readonly aNumbers: string[];
    readonly callIds: string[];
    readonly sourceIPs: string[];
    readonly distinctCallers: number;
    readonly status: AlertStatus;
    readonly acknowledgedBy?: string;
    readonly acknowledgedAt?: Date;
    readonly resolvedBy?: string;
    readonly resolvedAt?: Date;
    readonly resolution?: ResolutionType;
    readonly nccReported: boolean;
    readonly nccReportId?: string;
    readonly detectedAt: Date;
    readonly updatedAt: Date;
}

export type AlertStatus =
    | 'PENDING'
    | 'ACKNOWLEDGED'
    | 'INVESTIGATING'
    | 'RESOLVED'
    | 'REPORTED_NCC';

export type ResolutionType =
    | 'CONFIRMED_FRAUD'
    | 'FALSE_POSITIVE'
    | 'ESCALATED'
    | 'WHITELISTED';

/**
 * Gateway entity
 */
export interface Gateway {
    readonly id: string;
    readonly name: string;
    readonly ipAddress: IPAddress;
    readonly carrierName: string;
    readonly gatewayType: GatewayType;
    readonly isActive: boolean;
    readonly isBlacklisted: boolean;
    readonly blacklistReason?: string;
    readonly fraudThreshold: number;
    readonly cpmLimit: number;
    readonly acdThreshold: number;
    readonly createdAt: Date;
    readonly updatedAt: Date;
}

export type GatewayType = 'LOCAL' | 'INTERNATIONAL' | 'TRANSIT';

// ============================================================================
// Aggregates
// ============================================================================

/**
 * Call Aggregate Root
 */
export interface CallAggregate extends Call {
    flagAsFraud(alertId: string, score: FraudScore): CallAggregate;
    updateStatus(newStatus: CallStatus): CallAggregate;
    isPotentialCLIMasking(): boolean;
    isActive(): boolean;
}

/**
 * Alert Aggregate Root
 */
export interface AlertAggregate extends FraudAlert {
    acknowledge(userId: string): AlertAggregate;
    startInvestigation(): AlertAggregate;
    resolve(userId: string, resolution: ResolutionType, notes?: string): AlertAggregate;
    reportToNCC(reportId: string): AlertAggregate;
    shouldAutoEscalate(): boolean;
}

// ============================================================================
// Domain Events
// ============================================================================

export interface DomainEvent {
    readonly eventId: string;
    readonly eventType: string;
    readonly occurredAt: Date;
    readonly aggregateId: string;
}

export interface CallRegisteredEvent extends DomainEvent {
    readonly eventType: 'CallRegistered';
    readonly callId: string;
    readonly aNumber: string;
    readonly bNumber: string;
    readonly sourceIP: string;
}

export interface FraudDetectedEvent extends DomainEvent {
    readonly eventType: 'FraudDetected';
    readonly alertId: string;
    readonly bNumber: string;
    readonly fraudType: FraudType;
    readonly distinctCallers: number;
    readonly score: number;
}

export interface AlertAcknowledgedEvent extends DomainEvent {
    readonly eventType: 'AlertAcknowledged';
    readonly alertId: string;
    readonly acknowledgedBy: string;
}

export interface AlertResolvedEvent extends DomainEvent {
    readonly eventType: 'AlertResolved';
    readonly alertId: string;
    readonly resolvedBy: string;
    readonly resolution: ResolutionType;
}

export interface GatewayBlacklistedEvent extends DomainEvent {
    readonly eventType: 'GatewayBlacklisted';
    readonly gatewayId: string;
    readonly gatewayIP: string;
    readonly reason: string;
}

export interface NCCReportSubmittedEvent extends DomainEvent {
    readonly eventType: 'NCCReportSubmitted';
    readonly reportId: string;
    readonly alertIds: string[];
    readonly nccReference: string;
}

// ============================================================================
// Repository Interfaces
// ============================================================================

export interface CallRepository {
    save(call: Call): Promise<void>;
    findById(id: string): Promise<Call | null>;
    findCallsInWindow(bNumber: MSISDN, windowStart: Date, windowEnd: Date): Promise<Call[]>;
    countDistinctCallers(bNumber: MSISDN, windowStart: Date, windowEnd: Date): Promise<number>;
    flagAsFraud(callIds: string[], alertId: string): Promise<number>;
}

export interface AlertRepository {
    save(alert: FraudAlert): Promise<void>;
    findById(id: string): Promise<FraudAlert | null>;
    findPending(): Promise<FraudAlert[]>;
    findByStatus(status: AlertStatus): Promise<FraudAlert[]>;
    countPending(): Promise<number>;
}

export interface GatewayRepository {
    save(gateway: Gateway): Promise<void>;
    findById(id: string): Promise<Gateway | null>;
    findByIP(ip: string): Promise<Gateway | null>;
    findActive(): Promise<Gateway[]>;
    findBlacklisted(): Promise<Gateway[]>;
}
