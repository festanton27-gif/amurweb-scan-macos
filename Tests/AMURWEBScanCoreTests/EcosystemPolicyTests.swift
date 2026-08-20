import XCTest
@testable import AMURWEBScanCore

final class EcosystemPolicyTests: XCTestCase {
    func testFirstTenLaunchesHaveNoPromotion() {
        for launch in 1...10 {
            XCTAssertFalse(EcosystemLaunchPolicy.shouldShowPromotion(on: launch), "Launch \(launch) must be promotion-free")
        }
    }

    func testFiveOnTwoOffCycleStartsAtLaunchEleven() {
        for launch in 11...15 {
            XCTAssertTrue(EcosystemLaunchPolicy.shouldShowPromotion(on: launch), "Launch \(launch) must show promotion")
        }
        for launch in 16...17 {
            XCTAssertFalse(EcosystemLaunchPolicy.shouldShowPromotion(on: launch), "Launch \(launch) must be promotion-free")
        }
        for launch in 18...22 {
            XCTAssertTrue(EcosystemLaunchPolicy.shouldShowPromotion(on: launch), "Launch \(launch) must show promotion")
        }
        for launch in 23...24 {
            XCTAssertFalse(EcosystemLaunchPolicy.shouldShowPromotion(on: launch), "Launch \(launch) must be promotion-free")
        }
    }

    func testCycleKeepsRepeating() {
        XCTAssertTrue(EcosystemLaunchPolicy.shouldShowPromotion(on: 25))
        XCTAssertTrue(EcosystemLaunchPolicy.shouldShowPromotion(on: 29))
        XCTAssertFalse(EcosystemLaunchPolicy.shouldShowPromotion(on: 30))
        XCTAssertFalse(EcosystemLaunchPolicy.shouldShowPromotion(on: 31))
        XCTAssertTrue(EcosystemLaunchPolicy.shouldShowPromotion(on: 32))
    }

    func testVersionComparison() {
        XCTAssertTrue(VersionComparison.isNewer("0.5.1", than: "0.5.0"))
        XCTAssertTrue(VersionComparison.isNewer("1.0.0", than: "0.9.9"))
        XCTAssertFalse(VersionComparison.isNewer("0.5.0", than: "0.5.0 Alpha"))
        XCTAssertFalse(VersionComparison.isNewer("0.4.9", than: "0.5.0"))
    }
}
