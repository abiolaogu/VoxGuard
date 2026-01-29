import { describe, it, expect, beforeEach, vi } from 'vitest';

// ============================================================
// CLI SPOOFING DETECTION TESTS
// TDD: Red-Green-Refactor cycle
// ============================================================

// Mock types
interface CLI {
    e164Number: string;
    countryCode: string;
    nationalNumber: string;
    numberType: 'MOBILE' | 'FIXED' | 'VOIP' | 'PREMIUM' | 'TOLL_FREE';
    isValid: boolean;
    isAllocated: boolean;
}

interface SS7Analysis {
    originatingPointCode: string;
    callingPartyAddress: string;
    locationNumber?: string;
    inconsistencies: string[];
}

interface SIPHeaderAnalysis {
    fromHeader: string;
    pAssertedIdentity?: string;
    inconsistencies: string[];
}

interface STIRSHAKENResult {
    attestationLevel: 'A' | 'B' | 'C';
    verificationStatus: 'VERIFIED' | 'FAILED' | 'NO_SIGNATURE';
    certificateChainValid: boolean;
}

interface IncomingCall {
    presentedCLI: CLI;
    actualCLI?: CLI;
    ss7Data?: SS7Analysis;
    sipHeaders?: SIPHeaderAnalysis;
    stirShaken?: STIRSHAKENResult;
    networkOrigin: { countryCode: string };
    calledNumber: CLI;
}

interface SpoofingAnalysis {
    spoofingDetected: boolean;
    spoofingType: string;
    confidenceScore: number;
    indicators: string[];
}

// Detection service implementation (to be tested)
class CLISpoofingDetectionService {
    async detectSpoofing(call: IncomingCall): Promise<SpoofingAnalysis> {
        const indicators: string[] = [];
        let confidenceScore = 0;
        let spoofingType = 'NONE';

        // Check SS7 CPN mismatch
        if (call.ss7Data && call.presentedCLI.e164Number !== call.ss7Data.callingPartyAddress) {
            indicators.push('SS7_CPN_MISMATCH');
            confidenceScore += 0.35;
            spoofingType = 'CLI_MANIPULATION';
        }

        // Check SIP P-Asserted-Identity mismatch
        if (call.sipHeaders?.pAssertedIdentity &&
            call.sipHeaders.fromHeader !== call.sipHeaders.pAssertedIdentity) {
            indicators.push('SIP_PAI_MISMATCH');
            confidenceScore += 0.30;
            spoofingType = 'CLI_MANIPULATION';
        }

        // Check unallocated number
        if (!call.presentedCLI.isAllocated) {
            indicators.push('UNALLOCATED_NUMBER');
            confidenceScore += 0.40;
            spoofingType = 'NUMBER_SUBSTITUTION';
        }

        // Check neighbor spoofing (similar to called number)
        if (this.isSimilarNumber(call.presentedCLI.e164Number, call.calledNumber.e164Number, 6)) {
            indicators.push('NEIGHBOR_SPOOFING');
            confidenceScore += 0.25;
            spoofingType = 'NEIGHBOR_SPOOFING';
        }

        // Check STIR/SHAKEN failure
        if (call.stirShaken?.verificationStatus === 'FAILED') {
            indicators.push('STIR_SHAKEN_FAILED');
            confidenceScore += 0.35;
            spoofingType = spoofingType === 'NONE' ? 'CLI_MANIPULATION' : spoofingType;
        }

        // Check geographic inconsistency
        if (call.presentedCLI.countryCode !== call.networkOrigin.countryCode) {
            indicators.push('GEOGRAPHIC_INCONSISTENCY');
            confidenceScore += 0.15;
        }

        return {
            spoofingDetected: confidenceScore >= 0.30,
            spoofingType: confidenceScore >= 0.30 ? spoofingType : 'NONE',
            confidenceScore: Math.min(confidenceScore, 1.0),
            indicators,
        };
    }

    private isSimilarNumber(a: string, b: string, matchDigits: number): boolean {
        // Check if first N digits match (neighbor spoofing pattern)
        const aPrefix = a.replace(/\D/g, '').slice(0, matchDigits);
        const bPrefix = b.replace(/\D/g, '').slice(0, matchDigits);
        return aPrefix === bPrefix && a !== b;
    }

    analyzeSS7Consistency(ss7Data: SS7Analysis): { isConsistent: boolean; issues: string[] } {
        const issues: string[] = [];

        if (ss7Data.inconsistencies.length > 0) {
            issues.push(...ss7Data.inconsistencies);
        }

        return {
            isConsistent: issues.length === 0,
            issues,
        };
    }

    verifySTIRSHAKEN(result: STIRSHAKENResult): { verified: boolean; level: string } {
        return {
            verified: result.verificationStatus === 'VERIFIED' && result.certificateChainValid,
            level: result.attestationLevel,
        };
    }
}

// ============================================================
// TEST SUITE
// ============================================================

describe('CLISpoofingDetectionService', () => {
    let service: CLISpoofingDetectionService;

    beforeEach(() => {
        service = new CLISpoofingDetectionService();
    });

    // Helper to create test calls
    const createBaseCLI = (override: Partial<CLI> = {}): CLI => ({
        e164Number: '+2348012345678',
        countryCode: '+234',
        nationalNumber: '8012345678',
        numberType: 'MOBILE',
        isValid: true,
        isAllocated: true,
        ...override,
    });

    const createBaseCall = (override: Partial<IncomingCall> = {}): IncomingCall => ({
        presentedCLI: createBaseCLI(),
        networkOrigin: { countryCode: '+234' },
        calledNumber: createBaseCLI({ e164Number: '+2349087654321' }),
        ...override,
    });

    describe('detectSpoofing', () => {
        it('should detect SS7 CPN mismatch', async () => {
            const call = createBaseCall({
                presentedCLI: createBaseCLI({ e164Number: '+2348012345678' }),
                ss7Data: {
                    originatingPointCode: '1234',
                    callingPartyAddress: '+2349999999999', // Different from presented
                    inconsistencies: [],
                },
            });

            const result = await service.detectSpoofing(call);

            expect(result.spoofingDetected).toBe(true);
            expect(result.spoofingType).toBe('CLI_MANIPULATION');
            expect(result.indicators).toContain('SS7_CPN_MISMATCH');
            expect(result.confidenceScore).toBeGreaterThanOrEqual(0.35);
        });

        it('should detect SIP P-Asserted-Identity mismatch', async () => {
            const call = createBaseCall({
                sipHeaders: {
                    fromHeader: '+2348012345678',
                    pAssertedIdentity: '+2349999999999', // Different
                    inconsistencies: [],
                },
            });

            const result = await service.detectSpoofing(call);

            expect(result.spoofingDetected).toBe(true);
            expect(result.indicators).toContain('SIP_PAI_MISMATCH');
        });

        it('should detect unallocated number', async () => {
            const call = createBaseCall({
                presentedCLI: createBaseCLI({ isAllocated: false }),
            });

            const result = await service.detectSpoofing(call);

            expect(result.spoofingDetected).toBe(true);
            expect(result.spoofingType).toBe('NUMBER_SUBSTITUTION');
            expect(result.indicators).toContain('UNALLOCATED_NUMBER');
            expect(result.confidenceScore).toBeGreaterThanOrEqual(0.40);
        });

        it('should detect neighbor spoofing pattern', async () => {
            const call = createBaseCall({
                presentedCLI: createBaseCLI({ e164Number: '+2348031111111' }),
                calledNumber: createBaseCLI({ e164Number: '+2348031111112' }), // Very similar
            });

            const result = await service.detectSpoofing(call);

            expect(result.spoofingDetected).toBe(true);
            expect(result.spoofingType).toBe('NEIGHBOR_SPOOFING');
            expect(result.indicators).toContain('NEIGHBOR_SPOOFING');
        });

        it('should detect STIR/SHAKEN verification failure', async () => {
            const call = createBaseCall({
                stirShaken: {
                    attestationLevel: 'A',
                    verificationStatus: 'FAILED',
                    certificateChainValid: false,
                },
            });

            const result = await service.detectSpoofing(call);

            expect(result.spoofingDetected).toBe(true);
            expect(result.indicators).toContain('STIR_SHAKEN_FAILED');
        });

        it('should detect geographic inconsistency', async () => {
            const call = createBaseCall({
                presentedCLI: createBaseCLI({ countryCode: '+234' }),
                networkOrigin: { countryCode: '+44' }, // UK origin claiming Nigerian number
            });

            const result = await service.detectSpoofing(call);

            expect(result.indicators).toContain('GEOGRAPHIC_INCONSISTENCY');
        });

        it('should pass legitimate call without flags', async () => {
            const call = createBaseCall({
                ss7Data: {
                    originatingPointCode: '1234',
                    callingPartyAddress: '+2348012345678', // Same as presented
                    inconsistencies: [],
                },
                sipHeaders: {
                    fromHeader: '+2348012345678',
                    pAssertedIdentity: '+2348012345678', // Same
                    inconsistencies: [],
                },
                stirShaken: {
                    attestationLevel: 'A',
                    verificationStatus: 'VERIFIED',
                    certificateChainValid: true,
                },
            });

            const result = await service.detectSpoofing(call);

            expect(result.spoofingDetected).toBe(false);
            expect(result.spoofingType).toBe('NONE');
            expect(result.indicators).toHaveLength(0);
        });

        it('should combine multiple indicators for higher confidence', async () => {
            const call = createBaseCall({
                presentedCLI: createBaseCLI({ isAllocated: false }),
                ss7Data: {
                    originatingPointCode: '1234',
                    callingPartyAddress: '+9999999999',
                    inconsistencies: ['CPN_MISMATCH'],
                },
                stirShaken: {
                    attestationLevel: 'C',
                    verificationStatus: 'FAILED',
                    certificateChainValid: false,
                },
            });

            const result = await service.detectSpoofing(call);

            expect(result.spoofingDetected).toBe(true);
            expect(result.confidenceScore).toBeGreaterThanOrEqual(0.75);
            expect(result.indicators.length).toBeGreaterThanOrEqual(2);
        });
    });

    describe('analyzeSS7Consistency', () => {
        it('should detect SS7 inconsistencies', () => {
            const ss7Data: SS7Analysis = {
                originatingPointCode: '1234',
                callingPartyAddress: '+2348012345678',
                inconsistencies: ['LOCATION_NUMBER_MISMATCH', 'CHARGE_NUMBER_INVALID'],
            };

            const result = service.analyzeSS7Consistency(ss7Data);

            expect(result.isConsistent).toBe(false);
            expect(result.issues).toContain('LOCATION_NUMBER_MISMATCH');
        });

        it('should pass consistent SS7 data', () => {
            const ss7Data: SS7Analysis = {
                originatingPointCode: '1234',
                callingPartyAddress: '+2348012345678',
                inconsistencies: [],
            };

            const result = service.analyzeSS7Consistency(ss7Data);

            expect(result.isConsistent).toBe(true);
            expect(result.issues).toHaveLength(0);
        });
    });

    describe('verifySTIRSHAKEN', () => {
        it('should verify valid STIR/SHAKEN attestation', () => {
            const result = service.verifySTIRSHAKEN({
                attestationLevel: 'A',
                verificationStatus: 'VERIFIED',
                certificateChainValid: true,
            });

            expect(result.verified).toBe(true);
            expect(result.level).toBe('A');
        });

        it('should fail invalid certificate chain', () => {
            const result = service.verifySTIRSHAKEN({
                attestationLevel: 'A',
                verificationStatus: 'VERIFIED',
                certificateChainValid: false,
            });

            expect(result.verified).toBe(false);
        });

        it('should fail STIR/SHAKEN verification failure', () => {
            const result = service.verifySTIRSHAKEN({
                attestationLevel: 'C',
                verificationStatus: 'FAILED',
                certificateChainValid: true,
            });

            expect(result.verified).toBe(false);
        });
    });
});
