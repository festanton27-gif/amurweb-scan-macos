import XCTest
@testable import AMURWEBScanCore

final class ScannerVisibilityPolicyTests: XCTestCase {
    func testTestDevicesAreHiddenByDefault() {
        let hardware = ScannerDevice(id: "hw", name: "Real Scanner", isMock: false)
        let mock = ScannerDevice(id: "mock", name: "Mock Scanner", isMock: true)

        let visible = ScannerVisibilityPolicy.visibleDevices(
            from: [hardware, mock],
            includeTestDevices: false
        )

        XCTAssertEqual(visible.map(\.id), ["hw"])
    }

    func testTestDevicesCanBeEnabled() {
        let hardware = ScannerDevice(id: "hw", name: "Real Scanner", isMock: false)
        let mock = ScannerDevice(id: "mock", name: "Mock Scanner", isMock: true)

        let visible = ScannerVisibilityPolicy.visibleDevices(
            from: [hardware, mock],
            includeTestDevices: true
        )

        XCTAssertEqual(visible.map(\.id), ["hw", "mock"])
    }

    func testOnlyMockDevicesProduceEmptyNormalList() {
        let mock = ScannerDevice(id: "mock", name: "Mock Scanner", isMock: true)

        let visible = ScannerVisibilityPolicy.visibleDevices(
            from: [mock],
            includeTestDevices: false
        )

        XCTAssertTrue(visible.isEmpty)
    }
}
