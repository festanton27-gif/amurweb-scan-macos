import Foundation
import AMURWEBScanCore

/// Placeholder for the real macOS scanner transport.
///
/// 0.1.0 Alpha intentionally uses MockScannerBackend so that the complete UI,
/// Finder workflow, file naming, JPG/PNG/PDF and CI packaging can be tested
/// without physical scanner hardware. The next stage will implement this
/// backend using Apple's ImageCaptureCore framework.
struct ImageCaptureScannerBackend: ScannerBackend {
    let backendName = "ImageCaptureCore"

    func listDevices() async throws -> [ScannerDevice] {
        throw ScannerBackendError.unavailable("ImageCaptureCore hardware backend is scheduled for the next alpha build.")
    }

    func scan(_ request: ScanRequest) async throws -> ScanResult {
        throw ScannerBackendError.unavailable("ImageCaptureCore hardware backend is scheduled for the next alpha build.")
    }
}
