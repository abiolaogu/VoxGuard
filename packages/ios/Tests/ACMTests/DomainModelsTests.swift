import Foundation
import XCTest

@testable import ACMDomain

final class NigerianMNOTests: XCTestCase {
    
    // MARK: - MTN Tests
    
    func testMTN_DetectedFromAllPrefixes() {
        let mtnPrefixes = [
            "0703", "0706", "0803", "0806", "0810",
            "0813", "0814", "0816", "0903", "0906", "0913"
        ]
        
        for prefix in mtnPrefixes {
            let number = "\(prefix)1234567"
            let detected = NigerianMNO.detect(from: number)
            XCTAssertEqual(detected, .mtn, "Failed for prefix: \(prefix)")
        }
    }
    
    func testMTN_DetectedFromInternationalFormat() {
        let numbers = [
            "+2348030001234",
            "2348030001234",
            "+234 803 000 1234"
        ]
        
        for number in numbers {
            let detected = NigerianMNO.detect(from: number)
            XCTAssertEqual(detected, .mtn, "Failed for number: \(number)")
        }
    }
    
    // MARK: - Glo Tests
    
    func testGlo_DetectedFromAllPrefixes() {
        let gloPrefixes = ["0705", "0805", "0807", "0811", "0815", "0905"]
        
        for prefix in gloPrefixes {
            let number = "\(prefix)1234567"
            let detected = NigerianMNO.detect(from: number)
            XCTAssertEqual(detected, .glo, "Failed for prefix: \(prefix)")
        }
    }
    
    // MARK: - Airtel Tests
    
    func testAirtel_DetectedFromAllPrefixes() {
        let airtelPrefixes = [
            "0701", "0708", "0802", "0808", "0812",
            "0901", "0902", "0904", "0907", "0912"
        ]
        
        for prefix in airtelPrefixes {
            let number = "\(prefix)1234567"
            let detected = NigerianMNO.detect(from: number)
            XCTAssertEqual(detected, .airtel, "Failed for prefix: \(prefix)")
        }
    }
    
    // MARK: - 9mobile Tests
    
    func test9mobile_DetectedFromAllPrefixes() {
        let nineMobilePrefixes = ["0809", "0817", "0818", "0908", "0909"]
        
        for prefix in nineMobilePrefixes {
            let number = "\(prefix)1234567"
            let detected = NigerianMNO.detect(from: number)
            XCTAssertEqual(detected, .nineMobile, "Failed for prefix: \(prefix)")
        }
    }
    
    // MARK: - Unknown Tests
    
    func testUnknown_ReturnedForInvalidNumbers() {
        let invalidNumbers = [
            "",
            "12345",
            "abcdefgh",
            "+1234567890", // Non-Nigerian
            "0000123456" // Invalid prefix
        ]
        
        for number in invalidNumbers {
            let detected = NigerianMNO.detect(from: number)
            XCTAssertEqual(detected, .unknown, "Should be unknown for: \(number)")
        }
    }
    
    // MARK: - Display Name Tests
    
    func testDisplayName_ReturnsCorrectName() {
        XCTAssertEqual(NigerianMNO.mtn.displayName, "MTN Nigeria")
        XCTAssertEqual(NigerianMNO.glo.displayName, "Globacom")
        XCTAssertEqual(NigerianMNO.airtel.displayName, "Airtel Nigeria")
        XCTAssertEqual(NigerianMNO.nineMobile.displayName, "9mobile")
        XCTAssertEqual(NigerianMNO.unknown.displayName, "Unknown")
    }
}

final class NigerianStateTests: XCTestCase {
    
    func testDisplayName_ReturnsCorrectName() {
        XCTAssertEqual(NigerianState.akwaIbom.displayName, "Akwa Ibom")
        XCTAssertEqual(NigerianState.crossRiver.displayName, "Cross River")
        XCTAssertEqual(NigerianState.fct.displayName, "Federal Capital Territory")
        XCTAssertEqual(NigerianState.lagos.displayName, "Lagos")
    }
    
    func testRegion_ReturnsCorrectZone() {
        // South West
        XCTAssertEqual(NigerianState.lagos.region, .southWest)
        XCTAssertEqual(NigerianState.ogun.region, .southWest)
        XCTAssertEqual(NigerianState.oyo.region, .southWest)
        
        // South East
        XCTAssertEqual(NigerianState.abia.region, .southEast)
        XCTAssertEqual(NigerianState.anambra.region, .southEast)
        XCTAssertEqual(NigerianState.enugu.region, .southEast)
        
        // South South
        XCTAssertEqual(NigerianState.rivers.region, .southSouth)
        XCTAssertEqual(NigerianState.delta.region, .southSouth)
        
        // North Central
        XCTAssertEqual(NigerianState.fct.region, .northCentral)
        XCTAssertEqual(NigerianState.plateau.region, .northCentral)
        
        // North West  
        XCTAssertEqual(NigerianState.kano.region, .northWest)
        XCTAssertEqual(NigerianState.kaduna.region, .northWest)
        
        // North East
        XCTAssertEqual(NigerianState.borno.region, .northEast)
        XCTAssertEqual(NigerianState.adamawa.region, .northEast)
    }
    
    func testAllCases_Contains37States() {
        // Nigeria has 36 states + FCT = 37 total
        XCTAssertEqual(NigerianState.allCases.count, 37)
    }
}

final class CurrencyTests: XCTestCase {
    
    func testSymbol_ReturnsCorrectSymbol() {
        XCTAssertEqual(Currency.ngn.symbol, "₦")
        XCTAssertEqual(Currency.usd.symbol, "$")
        XCTAssertEqual(Currency.gbp.symbol, "£")
        XCTAssertEqual(Currency.eur.symbol, "€")
        XCTAssertEqual(Currency.cad.symbol, "C$")
        XCTAssertEqual(Currency.zar.symbol, "R")
    }
    
    func testFlag_ReturnsCorrectEmoji() {
        XCTAssertEqual(Currency.ngn.flag, "🇳🇬")
        XCTAssertEqual(Currency.usd.flag, "🇺🇸")
        XCTAssertEqual(Currency.gbp.flag, "🇬🇧")
        XCTAssertEqual(Currency.eur.flag, "🇪🇺")
        XCTAssertEqual(Currency.cad.flag, "🇨🇦")
        XCTAssertEqual(Currency.zar.flag, "🇿🇦")
    }
}

final class CallVerificationTests: XCTestCase {
    
    func testRiskLevel_ReturnsCorrectLevel() {
        let lowRisk = CallVerification(
            id: .init(rawValue: UUID()),
            callerNumber: "+2348030000000",
            calleeNumber: "+2349010000000",
            originalCLI: "+2348030000000",
            maskingDetected: false,
            confidenceScore: 0.2,
            status: .verified
        )
        XCTAssertEqual(lowRisk.riskLevel, .low)
        
        let mediumRisk = CallVerification(
            id: .init(rawValue: UUID()),
            callerNumber: "+2348030000000",
            calleeNumber: "+2349010000000",
            originalCLI: "+2348030000000",
            maskingDetected: true,
            confidenceScore: 0.6,
            status: .maskingDetected
        )
        XCTAssertEqual(mediumRisk.riskLevel, .medium)
        
        let highRisk = CallVerification(
            id: .init(rawValue: UUID()),
            callerNumber: "+2348030000000",
            calleeNumber: "+2349010000000",
            originalCLI: "+2348030000000",
            maskingDetected: true,
            confidenceScore: 0.8,
            status: .maskingDetected
        )
        XCTAssertEqual(highRisk.riskLevel, .high)
        
        let criticalRisk = CallVerification(
            id: .init(rawValue: UUID()),
            callerNumber: "+2348030000000",
            calleeNumber: "+2349010000000",
            originalCLI: "+2348030000000",
            maskingDetected: true,
            confidenceScore: 0.95,
            status: .maskingDetected
        )
        XCTAssertEqual(criticalRisk.riskLevel, .critical)
    }
    
    func testIsSafe_ReturnsCorrectValue() {
        let safeCall = CallVerification(
            id: .init(rawValue: UUID()),
            callerNumber: "+2348030000000",
            calleeNumber: "+2349010000000",
            originalCLI: "+2348030000000",
            maskingDetected: false,
            confidenceScore: 0.2,
            status: .verified
        )
        XCTAssertTrue(safeCall.isSafe)
        
        let unsafeCall = CallVerification(
            id: .init(rawValue: UUID()),
            callerNumber: "+2348030000000",
            calleeNumber: "+2349010000000",
            originalCLI: "+2348030000000",
            maskingDetected: true,
            confidenceScore: 0.85,
            status: .maskingDetected
        )
        XCTAssertFalse(unsafeCall.isSafe)
    }
}
