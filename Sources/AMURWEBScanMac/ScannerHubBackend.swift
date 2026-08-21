import Foundation
import AMURWEBScanCore

@MainActor
final class ScannerHubBackend: ScannerBackend {
    let backendName = "ImageCaptureCore + Mock"

    private let hardware = ImageCaptureScannerBackend()
    private let mock = MockScannerBackend()
    private let trace = DiagnosticSessionTrace.shared

    func listDevices() async throws -> [ScannerDevice] {
        trace.record("device_refresh_started")

        var result: [ScannerDevice] = []
        do {
            result.append(contentsOf: try await hardware.listDevices())
        } catch {
            trace.record("hardware_discovery_failed", details: errorDetails(error))
            // Keep Mock Scanner available even when ImageCaptureCore discovery fails.
        }

        result.append(contentsOf: try await mock.listDevices())
        trace.record(
            "device_refresh_completed",
            details: [
                "hardware": String(result.filter { !$0.isMock }.count),
                "mock": String(result.filter { $0.isMock }.count)
            ]
        )
        return result
    }

    func scan(_ request: ScanRequest) async throws -> ScanResult {
        trace.record(
            "scan_started",
            details: [
                "device": request.device.name,
                "kind": request.device.isMock ? "mock" : "hardware",
                "source": request.source.rawValue,
                "dpi": String(request.dpi),
                "format": request.format.rawValue,
                "duplex": request.duplexEnabled ? "yes" : "no"
            ]
        )

        do {
            let result: ScanResult
            if request.device.isMock {
                result = try await mock.scan(request)
            } else {
                result = try await hardware.scan(request)
            }

            trace.record(
                "scan_completed",
                details: [
                    "kind": request.device.isMock ? "mock" : "hardware",
                    "outputs": String(result.fileURLs.count)
                ]
            )
            return result
        } catch {
            var details = errorDetails(error)
            details["kind"] = request.device.isMock ? "mock" : "hardware"
            trace.record("scan_failed", details: details)
            throw error
        }
    }

    func cancelScan() {
        trace.record("scan_cancel_requested")
        hardware.cancelScan()
        mock.cancelScan()
    }

    func diagnosticReport() async -> String {
        trace.record("diagnostics_backend_report_requested")
        let hardwareReport = await hardware.diagnosticReport()
        trace.record("diagnostics_backend_report_ready")
        return hardwareReport + "\n\nMock Scanner\nVirtual flatbed: available\nVirtual ADF: available\nVirtual ADF pages: 3 simplex / 4 duplex\nJPG/PNG/PDF: enabled\nCancellation: enabled"
    }

    private func errorDetails(_ error: Error) -> [String: String] {
        let nsError = error as NSError
        return [
            "domain": nsError.domain,
            "code": String(nsError.code)
        ]
    }
}
