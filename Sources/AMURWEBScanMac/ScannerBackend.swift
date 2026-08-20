import Foundation
import AMURWEBScanCore

@MainActor
protocol ScannerBackend {
    var backendName: String { get }
    func listDevices() async throws -> [ScannerDevice]
    func scan(_ request: ScanRequest) async throws -> ScanResult
    func cancelScan()
    func diagnosticReport() async -> String
}

extension ScannerBackend {
    func cancelScan() {}

    func diagnosticReport() async -> String {
        "Backend: \(backendName)"
    }
}
