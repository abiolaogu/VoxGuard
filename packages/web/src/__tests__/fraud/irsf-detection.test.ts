import { describe, it, expect, beforeEach } from 'vitest';

// ============================================================
// IRSF (International Revenue Share Fraud) DETECTION TESTS
// ============================================================

interface IRSFDestination {
    countryCode: string;
    prefix: string;
    riskLevel: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW';
    isBlacklisted: boolean;
}

interface IRSFIndicator {
    type: string;
    weight: number;
    details: string;
}

interface CallRecord {
    sourceNumber: string;
    destinationNumber: string;
    destinationCountry: string;
    callDurationSeconds: number;
    timestamp: Date;
}

interface IRSFAnalysis {
    isIRSFRisk: boolean;
    riskLevel: string;
    riskScore: number;
    indicators: IRSFIndicator[];
    estimatedLoss: number;
    recommendedAction: 'BLOCK' | 'MONITOR' | 'ALLOW';
}

// High-risk IRSF destinations (subset)
const IRSF_DESTINATIONS: IRSFDestination[] = [
    { countryCode: '+960', prefix: '960', riskLevel: 'CRITICAL', isBlacklisted: false },
    { countryCode: '+675', prefix: '675', riskLevel: 'CRITICAL', isBlacklisted: false },
    { countryCode: '+252', prefix: '252', riskLevel: 'CRITICAL', isBlacklisted: false },
    { countryCode: '+881', prefix: '881', riskLevel: 'HIGH', isBlacklisted: false },
    { countryCode: '+882', prefix: '882', riskLevel: 'HIGH', isBlacklisted: false },
    { countryCode: '+1', prefix: '1900', riskLevel: 'MEDIUM', isBlacklisted: false },
];

// IRSF Detection Service
class IRSFDetectionService {
    private destinations: IRSFDestination[];
    private ratePerMinute = 150; // NGN per minute for high-risk

    constructor(destinations: IRSFDestination[] = IRSF_DESTINATIONS) {
        this.destinations = destinations;
    }

    analyzeDestination(destinationNumber: string): IRSFAnalysis {
        const indicators: IRSFIndicator[] = [];
        let riskScore = 0;

        // Find matching destination
        const matchedDest = this.findMatchingDestination(destinationNumber);

        if (matchedDest) {
            const riskWeights = {
                CRITICAL: 0.45,
                HIGH: 0.35,
                MEDIUM: 0.20,
                LOW: 0.05,
            };

            riskScore += riskWeights[matchedDest.riskLevel];
            indicators.push({
                type: 'HIGH_RISK_DESTINATION',
                weight: riskWeights[matchedDest.riskLevel],
                details: `Destination ${matchedDest.countryCode} is ${matchedDest.riskLevel} risk`,
            });

            if (matchedDest.isBlacklisted) {
                riskScore += 0.50;
                indicators.push({
                    type: 'BLACKLISTED_DESTINATION',
                    weight: 0.50,
                    details: 'Destination is blacklisted',
                });
            }
        }

        return {
            isIRSFRisk: riskScore >= 0.20,
            riskLevel: matchedDest?.riskLevel ?? 'LOW',
            riskScore: Math.min(riskScore, 1.0),
            indicators,
            estimatedLoss: 0, // Calculated separately
            recommendedAction: this.getRecommendedAction(riskScore),
        };
    }

    detectTrafficPumping(calls: CallRecord[]): { isPumping: boolean; callCount: number; pattern: string } {
        if (calls.length < 10) {
            return { isPumping: false, callCount: calls.length, pattern: 'NORMAL' };
        }

        // Check for same destination pattern
        const destinations = new Set(calls.map(c => c.destinationNumber));
        const sameDestRatio = 1 - (destinations.size / calls.length);

        // Check for short holding time pattern
        const avgDuration = calls.reduce((sum, c) => sum + c.callDurationSeconds, 0) / calls.length;
        const shortHoldingTime = avgDuration < 60 && avgDuration > 30; // 30-60 seconds typical for billing

        // Check for velocity
        const timeSpan = Math.abs(
            calls[calls.length - 1].timestamp.getTime() - calls[0].timestamp.getTime()
        ) / 1000 / 60; // minutes
        const callsPerMinute = calls.length / Math.max(timeSpan, 1);

        const isPumping =
            sameDestRatio > 0.8 ||
            (shortHoldingTime && callsPerMinute > 5) ||
            callsPerMinute > 10;

        return {
            isPumping,
            callCount: calls.length,
            pattern: isPumping ? 'TRAFFIC_PUMPING' : 'NORMAL',
        };
    }

    calculateEstimatedLoss(durationSeconds: number, riskLevel: string): number {
        const rates: Record<string, number> = {
            CRITICAL: 200,
            HIGH: 150,
            MEDIUM: 100,
            LOW: 50,
        };
        const rate = rates[riskLevel] ?? 50;
        return (durationSeconds / 60) * rate;
    }

    private findMatchingDestination(number: string): IRSFDestination | undefined {
        const cleanNumber = number.replace(/\D/g, '');
        return this.destinations
            .filter(d => cleanNumber.startsWith(d.prefix.replace('+', '')))
            .sort((a, b) => b.prefix.length - a.prefix.length)[0];
    }

    private getRecommendedAction(riskScore: number): 'BLOCK' | 'MONITOR' | 'ALLOW' {
        if (riskScore >= 0.70) return 'BLOCK';
        if (riskScore >= 0.30) return 'MONITOR';
        return 'ALLOW';
    }
}

// ============================================================
// TEST SUITE
// ============================================================

describe('IRSFDetectionService', () => {
    let service: IRSFDetectionService;

    beforeEach(() => {
        service = new IRSFDetectionService();
    });

    describe('analyzeDestination', () => {
        it('should flag Maldives (+960) as CRITICAL risk', () => {
            const result = service.analyzeDestination('+96012345678');

            expect(result.isIRSFRisk).toBe(true);
            expect(result.riskLevel).toBe('CRITICAL');
            expect(result.riskScore).toBeGreaterThanOrEqual(0.45);
            expect(result.recommendedAction).toBe('BLOCK');
        });

        it('should flag Papua New Guinea (+675) as CRITICAL risk', () => {
            const result = service.analyzeDestination('+67512345678');

            expect(result.isIRSFRisk).toBe(true);
            expect(result.riskLevel).toBe('CRITICAL');
        });

        it('should flag Somalia (+252) as CRITICAL risk', () => {
            const result = service.analyzeDestination('+25212345678');

            expect(result.isIRSFRisk).toBe(true);
            expect(result.riskLevel).toBe('CRITICAL');
        });

        it('should flag satellite numbers (+881) as HIGH risk', () => {
            const result = service.analyzeDestination('+88112345678');

            expect(result.isIRSFRisk).toBe(true);
            expect(result.riskLevel).toBe('HIGH');
            expect(result.recommendedAction).toBe('MONITOR');
        });

        it('should flag US premium (+1900) as MEDIUM risk', () => {
            const result = service.analyzeDestination('+19001234567');

            expect(result.isIRSFRisk).toBe(true);
            expect(result.riskLevel).toBe('MEDIUM');
        });

        it('should allow legitimate US number', () => {
            const result = service.analyzeDestination('+14155551234');

            expect(result.isIRSFRisk).toBe(false);
            expect(result.riskLevel).toBe('LOW');
            expect(result.recommendedAction).toBe('ALLOW');
        });

        it('should allow legitimate UK number', () => {
            const result = service.analyzeDestination('+442071234567');

            expect(result.isIRSFRisk).toBe(false);
            expect(result.recommendedAction).toBe('ALLOW');
        });

        it('should allow legitimate Nigerian number', () => {
            const result = service.analyzeDestination('+2348012345678');

            expect(result.isIRSFRisk).toBe(false);
            expect(result.recommendedAction).toBe('ALLOW');
        });

        it('should increase risk for blacklisted destinations', () => {
            const serviceWithBlacklist = new IRSFDetectionService([
                { countryCode: '+960', prefix: '960', riskLevel: 'CRITICAL', isBlacklisted: true },
            ]);

            const result = serviceWithBlacklist.analyzeDestination('+96012345678');

            expect(result.riskScore).toBeGreaterThanOrEqual(0.90);
            expect(result.recommendedAction).toBe('BLOCK');
            expect(result.indicators.some(i => i.type === 'BLACKLISTED_DESTINATION')).toBe(true);
        });
    });

    describe('detectTrafficPumping', () => {
        const createCalls = (count: number, sameDestination: boolean = false): CallRecord[] => {
            const baseTime = new Date();
            return Array.from({ length: count }, (_, i) => ({
                sourceNumber: '+2348012345678',
                destinationNumber: sameDestination
                    ? '+96012345678'
                    : `+9601234${String(i).padStart(4, '0')}`,
                destinationCountry: '+960',
                callDurationSeconds: 45, // Typical billing window
                timestamp: new Date(baseTime.getTime() + i * 10000), // 10 seconds apart
            }));
        };

        it('should detect traffic pumping with same destination', () => {
            const calls = createCalls(20, true); // 20 calls to same number

            const result = service.detectTrafficPumping(calls);

            expect(result.isPumping).toBe(true);
            expect(result.pattern).toBe('TRAFFIC_PUMPING');
        });

        it('should detect high velocity traffic pumping', () => {
            const calls = createCalls(50, false); // 50 calls in short time

            const result = service.detectTrafficPumping(calls);

            expect(result.isPumping).toBe(true);
        });

        it('should not flag normal call volume', () => {
            const calls = createCalls(5, false);

            const result = service.detectTrafficPumping(calls);

            expect(result.isPumping).toBe(false);
            expect(result.pattern).toBe('NORMAL');
        });
    });

    describe('calculateEstimatedLoss', () => {
        it('should calculate loss for CRITICAL destination', () => {
            const loss = service.calculateEstimatedLoss(300, 'CRITICAL'); // 5 minutes

            expect(loss).toBe(1000); // 5 min * 200 NGN/min
        });

        it('should calculate loss for HIGH destination', () => {
            const loss = service.calculateEstimatedLoss(600, 'HIGH'); // 10 minutes

            expect(loss).toBe(1500); // 10 min * 150 NGN/min
        });

        it('should calculate loss for long duration call', () => {
            const loss = service.calculateEstimatedLoss(3600, 'CRITICAL'); // 1 hour

            expect(loss).toBe(12000); // 60 min * 200 NGN/min
        });
    });
});
