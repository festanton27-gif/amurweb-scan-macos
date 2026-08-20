import Foundation
import AMURWEBScanCore

protocol ScannerBackend: Sendable {
    var backendName: String { get }
    func listDevices() async throws -> [ScannerDevice]
    func scan(_ request: ScanRequest) async throws -> ScanResult
}
