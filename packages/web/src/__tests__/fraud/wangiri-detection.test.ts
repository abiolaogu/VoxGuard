import { describe, it, expect, beforeEach } from 'vitest';

// ============================================================
// WANGIRI (ONE-RING) DETECTION TESTS
// ============================================================

interface MissedCall {
    sourceNumber: string;
    targetNumber: string;
    ringDurationMs: number;
    timestamp: Date;
}

interface WangiriAnalysis {
    isWangiri: boolean;
    confidenceScore: number;
    indicators: string[];
    recommendedAction: 'BLOCK_CALLBACK' | 'WARN_USER' | 'ALLOW';
}

interface WangiriCampaign {
    id: string;
    sourceNumbers: string[];
    totalAttempts: number;
    estimatedVictims: number;
    status: 'ACTIVE' | 'MITIGATED' | 'CLOSED';
}

// Detection thresholds
const WANGIRI_CONFIG = {
    ULTRA_SHORT_RING_MS: 2000,
    SHORT_RING_MS: 5000,
    MASS_DIAL_THRESHOLD: 100,
    CAMPAIGN_WINDOW_MINUTES: 60,
    OFF_HOURS_START: 23,
    OFF_HOURS_END: 6,
};

// High-risk callback destinations
const HIGH_COST_PREFIXES = ['+960', '+675', '+252', '+881', '+882', '+979'];

// Wangiri Detection Service
class WangiriDetectionService {
    analyzeMissedCall(call: MissedCall): WangiriAnalysis {
        const indicators: string[] = [];
        let score = 0;

        // Ultra-short ring (< 2 seconds)
        if (call.ringDurationMs < WANGIRI_CONFIG.ULTRA_SHORT_RING_MS) {
            indicators.push('ULTRA_SHORT_RING');
            score += 0.35;
        } else if (call.ringDurationMs < WANGIRI_CONFIG.SHORT_RING_MS) {
            indicators.push('SHORT_RING');
            score += 0.20;
        }

        // High-cost destination check
        if (this.isHighCostDestination(call.sourceNumber)) {
            indicators.push('HIGH_COST_DESTINATION');
            score += 0.25;
        }

        // Known Wangiri prefix
        if (this.isKnownWangiriPrefix(call.sourceNumber)) {
            indicators.push('KNOWN_WANGIRI_PREFIX');
            score += 0.15;
        }

        // Off-hours calling
        const hour = call.timestamp.getHours();
        if (hour >= WANGIRI_CONFIG.OFF_HOURS_START || hour < WANGIRI_CONFIG.OFF_HOURS_END) {
            indicators.push('OFF_HOURS_CALLING');
            score += 0.05;
        }

        return {
            isWangiri: score >= 0.35,
            confidenceScore: Math.min(score, 1.0),
            indicators,
            recommendedAction: this.getAction(score),
        };
    }

    detectCampaign(calls: MissedCall[]): WangiriCampaign | null {
        if (calls.length < 10) return null;

        // Group by source number
        const bySource = new Map<string, MissedCall[]>();
        calls.forEach(call => {
            const existing = bySource.get(call.sourceNumber) || [];
            existing.push(call);
            bySource.set(call.sourceNumber, existing);
        });

        // Find sources with high volume
        const campaignSources: string[] = [];
        let totalAttempts = 0;

        bySource.forEach((sourceCalls, sourceNumber) => {
            if (sourceCalls.length >= 10) {
                campaignSources.push(sourceNumber);
                totalAttempts += sourceCalls.length;
            }
        });

        if (campaignSources.length === 0) return null;

        // Estimate victims (unique targets)
        const uniqueTargets = new Set(calls.map(c => c.targetNumber)).size;

        return {
            id: `WANG-${Date.now()}`,
            sourceNumbers: campaignSources,
            totalAttempts,
            estimatedVictims: uniqueTargets,
            status: 'ACTIVE',
        };
    }

    detectMassDialing(calls: MissedCall[], sourceNumber: string): {
        isMassDialing: boolean;
        callCount: number;
        uniqueTargets: number;
    } {
        const sourceCalls = calls.filter(c => c.sourceNumber === sourceNumber);
        const uniqueTargets = new Set(sourceCalls.map(c => c.targetNumber)).size;

        return {
            isMassDialing: sourceCalls.length >= WANGIRI_CONFIG.MASS_DIAL_THRESHOLD,
            callCount: sourceCalls.length,
            uniqueTargets,
        };
    }

    shouldBlockCallback(targetNumber: string, sourceNumber: string, recentWangiri: boolean): boolean {
        // Always block callback to high-cost if recent wangiri
        if (recentWangiri && this.isHighCostDestination(sourceNumber)) {
            return true;
        }

        // Block callback to known wangiri sources
        if (this.isKnownWangiriPrefix(sourceNumber)) {
            return true;
        }

        return false;
    }

    private isHighCostDestination(number: string): boolean {
        return HIGH_COST_PREFIXES.some(prefix => number.startsWith(prefix));
    }

    private isKnownWangiriPrefix(number: string): boolean {
        // Known problematic ranges (simplified)
        const knownPrefixes = ['+960', '+675', '+252'];
        return knownPrefixes.some(prefix => number.startsWith(prefix));
    }

    private getAction(score: number): 'BLOCK_CALLBACK' | 'WARN_USER' | 'ALLOW' {
        if (score >= 0.60) return 'BLOCK_CALLBACK';
        if (score >= 0.35) return 'WARN_USER';
        return 'ALLOW';
    }
}

// ============================================================
// TEST SUITE
// ============================================================

describe('WangiriDetectionService', () => {
    let service: WangiriDetectionService;

    beforeEach(() => {
        service = new WangiriDetectionService();
    });

    const createMissedCall = (override: Partial<MissedCall> = {}): MissedCall => ({
        sourceNumber: '+96012345678',
        targetNumber: '+2348012345678',
        ringDurationMs: 1500,
        timestamp: new Date('2025-01-29T02:00:00'), // 2 AM (off hours)
        ...override,
    });

    describe('analyzeMissedCall', () => {
        it('should detect ultra-short ring wangiri', () => {
            const call = createMissedCall({ ringDurationMs: 1500 });

            const result = service.analyzeMissedCall(call);

            expect(result.isWangiri).toBe(true);
            expect(result.indicators).toContain('ULTRA_SHORT_RING');
            expect(result.confidenceScore).toBeGreaterThanOrEqual(0.35);
        });

        it('should detect high-cost destination', () => {
            const call = createMissedCall({
                sourceNumber: '+96012345678', // Maldives
                ringDurationMs: 3000,
            });

            const result = service.analyzeMissedCall(call);

            expect(result.indicators).toContain('HIGH_COST_DESTINATION');
        });

        it('should detect known wangiri prefix', () => {
            const call = createMissedCall({
                sourceNumber: '+67512345678', // Papua New Guinea
            });

            const result = service.analyzeMissedCall(call);

            expect(result.indicators).toContain('KNOWN_WANGIRI_PREFIX');
        });

        it('should detect off-hours calling', () => {
            const call = createMissedCall({
                timestamp: new Date('2025-01-29T03:30:00'), // 3:30 AM
            });

            const result = service.analyzeMissedCall(call);

            expect(result.indicators).toContain('OFF_HOURS_CALLING');
        });

        it('should recommend blocking high-confidence wangiri', () => {
            const call = createMissedCall({
                sourceNumber: '+96012345678', // High-cost
                ringDurationMs: 1500, // Ultra-short
                timestamp: new Date('2025-01-29T02:00:00'), // Off-hours
            });

            const result = service.analyzeMissedCall(call);

            expect(result.isWangiri).toBe(true);
            expect(result.recommendedAction).toBe('BLOCK_CALLBACK');
        });

        it('should recommend warning for medium-confidence', () => {
            const call = createMissedCall({
                sourceNumber: '+14155551234', // Normal US number
                ringDurationMs: 1800, // Ultra-short
            });

            const result = service.analyzeMissedCall(call);

            expect(result.recommendedAction).toBe('WARN_USER');
        });

        it('should allow normal missed call', () => {
            const call = createMissedCall({
                sourceNumber: '+2348099999999', // Nigerian number
                ringDurationMs: 15000, // Normal ring duration
                timestamp: new Date('2025-01-29T14:00:00'), // Normal hours
            });

            const result = service.analyzeMissedCall(call);

            expect(result.isWangiri).toBe(false);
            expect(result.recommendedAction).toBe('ALLOW');
        });

        it('should combine multiple indicators for higher confidence', () => {
            const call = createMissedCall({
                sourceNumber: '+96012345678', // High-cost + known prefix
                ringDurationMs: 1200, // Ultra-short
                timestamp: new Date('2025-01-29T01:00:00'), // Off-hours
            });

            const result = service.analyzeMissedCall(call);

            expect(result.confidenceScore).toBeGreaterThanOrEqual(0.75);
            expect(result.indicators.length).toBeGreaterThanOrEqual(3);
        });
    });

    describe('detectCampaign', () => {
        it('should detect mass dialing campaign', () => {
            const calls = Array.from({ length: 150 }, (_, i) =>
                createMissedCall({
                    sourceNumber: '+96012345678',
                    targetNumber: `+234801234${String(i).padStart(4, '0')}`,
                })
            );

            const result = service.detectCampaign(calls);

            expect(result).not.toBeNull();
            expect(result?.status).toBe('ACTIVE');
            expect(result?.totalAttempts).toBe(150);
            expect(result?.estimatedVictims).toBe(150);
        });

        it('should identify multiple source numbers in campaign', () => {
            const calls = [
                ...Array.from({ length: 50 }, () => createMissedCall({ sourceNumber: '+96011111111' })),
                ...Array.from({ length: 50 }, () => createMissedCall({ sourceNumber: '+96022222222' })),
            ];

            const result = service.detectCampaign(calls);

            expect(result?.sourceNumbers).toHaveLength(2);
        });

        it('should not flag small call volume as campaign', () => {
            const calls = Array.from({ length: 5 }, () => createMissedCall());

            const result = service.detectCampaign(calls);

            expect(result).toBeNull();
        });
    });

    describe('detectMassDialing', () => {
        it('should detect mass dialing from single source', () => {
            const sourceNumber = '+96012345678';
            const calls = Array.from({ length: 150 }, (_, i) =>
                createMissedCall({
                    sourceNumber,
                    targetNumber: `+234801234${String(i).padStart(4, '0')}`,
                })
            );

            const result = service.detectMassDialing(calls, sourceNumber);

            expect(result.isMassDialing).toBe(true);
            expect(result.callCount).toBe(150);
            expect(result.uniqueTargets).toBe(150);
        });

        it('should not flag normal source', () => {
            const calls = Array.from({ length: 5 }, () => createMissedCall());

            const result = service.detectMassDialing(calls, '+96012345678');

            expect(result.isMassDialing).toBe(false);
        });
    });

    describe('shouldBlockCallback', () => {
        it('should block callback to high-cost after wangiri', () => {
            const result = service.shouldBlockCallback(
                '+2348012345678', // Nigerian target
                '+96012345678',   // Maldives source
                true              // Recent wangiri
            );

            expect(result).toBe(true);
        });

        it('should block callback to known wangiri prefix', () => {
            const result = service.shouldBlockCallback(
                '+2348012345678',
                '+67512345678', // Papua New Guinea
                false
            );

            expect(result).toBe(true);
        });

        it('should allow callback to normal number', () => {
            const result = service.shouldBlockCallback(
                '+2348012345678',
                '+14155551234', // Normal US number
                false
            );

            expect(result).toBe(false);
        });
    });
});
