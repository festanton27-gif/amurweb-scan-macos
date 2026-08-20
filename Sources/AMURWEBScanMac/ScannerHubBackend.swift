import Foundation
import AMURWEBScanCore

@MainActor
final class ScannerHubBackend: ScannerBackend {
    let backendName = "ImageCaptureCore + Mock"

    private let hardware = ImageCaptureScannerBackend()
    private let mock = MockScannerBackend()

    func listDevices() async throws -> [ScannerDevice] {
        var result: [ScannerDevice] = []
        do {
            result.append(contentsOf: try await hardware.listDevices())
        } catch {
            // Keep Mock Scanner available even when ImageCaptureCore discovery fails.
        }
        result.append(contentsOf: try await mock.listDevices())
        return result
    }

    func scan(_ request: ScanRequest) async throws -> ScanResult {
        if request.device.isMock {
            return try await mock.scan(request)
        }
        return try await hardware.scan(request)
    }

    func diagnosticReport() async -> String {
        let hardwareReport = await hardware.diagnosticReport()
        return hardwareReport + "\n\nMock Scanner\nVirtual flatbed: available\nVirtual ADF: available\nVirtual ADF pages: 3 simplex / 4 duplex\nJPG/PNG/PDF: enabled"
    }
}
