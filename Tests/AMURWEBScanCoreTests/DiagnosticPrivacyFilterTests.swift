import XCTest
@testable import AMURWEBScanCore

final class DiagnosticPrivacyFilterTests: XCTestCase {
    func testPersistentScannerIDIsRedacted() {
        let source = "Scanner 1\nName: Test Scanner\nID: ic:serial:SECRET-123\nCurrent resolution: 300 DPI"
        let sanitized = DiagnosticPrivacyFilter.sanitize(source)

        XCTAssertFalse(sanitized.contains("SECRET-123"))
        XCTAssertTrue(sanitized.contains("ID: redacted"))
        XCTAssertTrue(sanitized.contains("Current resolution: 300 DPI"))
    }

    func testUnrelatedLinesRemainUnchanged() {
        let source = "Backend: ImageCaptureCore\nDetected hardware scanners: 1"
        XCTAssertEqual(DiagnosticPrivacyFilter.sanitize(source), source)
    }
}
