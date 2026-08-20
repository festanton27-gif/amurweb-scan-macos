import Foundation
import ImageCaptureCore
import UniformTypeIdentifiers
import AMURWEBScanCore

@MainActor
final class ImageCaptureScannerBackend: NSObject, ScannerBackend, @preconcurrency ICDeviceBrowserDelegate, @preconcurrency ICScannerDeviceDelegate {
    let backendName = "ImageCaptureCore"

    private let browser = ICDeviceBrowser()
    private var browserStarted = false
    private var scanners: [String: ICScannerDevice] = [:]

    private var activeRequest: ScanRequest?
    private var activeScanner: ICScannerDevice?
    private var scannedURLs: [URL] = []
    private var scanContinuation: CheckedContinuation<ScanResult, Error>?

    private var selectionScanner: ICScannerDevice?
    private var selectionContinuation: CheckedContinuation<Void, Error>?

    private let namer = ScanFileNamer()

    override init() {
        super.init()
        browser.delegate = self
    }

    func listDevices() async throws -> [ScannerDevice] {
        startBrowserIfNeeded()
        try await Task.sleep(nanoseconds: 700_000_000)
        return scanners
            .map { key, scanner in
                ScannerDevice(id: key, name: scanner.name ?? "Scanner", isMock: false)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func diagnosticReport() async -> String {
        startBrowserIfNeeded()
        try? await Task.sleep(nanoseconds: 700_000_000)

        var lines: [String] = [
            "AMURWEB Scan macOS 0.3.0 Alpha",
            "Backend: ImageCaptureCore",
            "Detected hardware scanners: \(scanners.count)",
            ""
        ]

        for (index, pair) in scanners.sorted(by: { ($0.value.name ?? "") < ($1.value.name ?? "") }).enumerated() {
            let (id, scanner) = pair
            let types = scanner.availableFunctionalUnitTypes.compactMap {
                ICScannerFunctionalUnitType(rawValue: UInt($0.uintValue))
            }.map(functionalUnitName).joined(separator: ", ")

            let unit = scanner.selectedFunctionalUnit
            let resolutions = unit.supportedResolutions.map(String.init).joined(separator: ", ")

            lines.append("Scanner \(index + 1)")
            lines.append("Name: \(scanner.name ?? "Scanner")")
            lines.append("ID: \(id)")
            lines.append("Session open: \(scanner.hasOpenSession ? "yes" : "no")")
            lines.append("USB vendor/product/location: \(scanner.usbVendorID)/\(scanner.usbProductID)/\(scanner.usbLocationID)")
            lines.append("Available sources: \(types.isEmpty ? "unknown" : types)")
            lines.append("Selected source: \(functionalUnitName(unit.type))")
            lines.append("Current resolution: \(unit.resolution) DPI")
            lines.append("Supported resolutions: \(resolutions.isEmpty ? "not reported" : resolutions)")
            lines.append("Physical size: \(Int(unit.physicalSize.width)) × \(Int(unit.physicalSize.height))")

            if let feeder = unit as? ICScannerFunctionalUnitDocumentFeeder {
                lines.append("ADF document loaded: \(feeder.documentLoaded ? "yes" : "no")")
                lines.append("ADF duplex supported: \(feeder.supportsDuplexScanning ? "yes" : "no")")
                lines.append("ADF duplex enabled: \(feeder.duplexScanningEnabled ? "yes" : "no")")
            }
            lines.append("")
        }

        if scanners.isEmpty {
            lines.append("No hardware scanner is currently visible to ImageCaptureCore.")
        }

        return lines.joined(separator: "\n")
    }

    func scan(_ request: ScanRequest) async throws -> ScanResult {
        guard scanContinuation == nil, selectionContinuation == nil else {
            throw ScannerBackendError.scanFailed("Another hardware scan is already in progress.")
        }
        guard let scanner = scanners[request.device.id] else {
            throw ScannerBackendError.noDevice
        }

        try FileManager.default.createDirectory(at: request.outputFolder, withIntermediateDirectories: true)

        activeRequest = request
        activeScanner = scanner
        scannedURLs.removeAll()
        scanner.delegate = self

        do {
            if !scanner.hasOpenSession {
                try await scanner.requestOpenSession(options: nil)
            }
            try await selectSourceIfNeeded(scanner: scanner, request: request)
            try configure(scanner: scanner, request: request)
        } catch {
            clearActiveScan()
            throw error
        }

        return try await withCheckedThrowingContinuation { continuation in
            scanContinuation = continuation
            scanner.requestScan()
        }
    }

    private func startBrowserIfNeeded() {
        guard !browserStarted else { return }
        let rawMask = ICDeviceTypeMask.scanner.rawValue |
            ICDeviceLocationTypeMask.local.rawValue |
            ICDeviceLocationTypeMask.shared.rawValue |
            ICDeviceLocationTypeMask.bonjour.rawValue |
            ICDeviceLocationTypeMask.bluetooth.rawValue |
            ICDeviceLocationTypeMask.remote.rawValue
        browser.browsedDeviceTypeMask = ICDeviceTypeMask(rawValue: rawMask) ?? .scanner
        browser.start()
        browserStarted = true
    }

    private func stableID(for scanner: ICScannerDevice) -> String {
        if let id = scanner.uuidString, !id.isEmpty { return "ic:\(id)" }
        if let id = scanner.persistentIDString, !id.isEmpty { return "ic:\(id)" }
        if let serial = scanner.serialNumberString, !serial.isEmpty {
            return "ic:serial:\(serial)"
        }
        return "ic:\(scanner.usbVendorID):\(scanner.usbProductID):\(scanner.usbLocationID):\(scanner.name ?? "scanner")"
    }

    private func functionalUnitName(_ type: ICScannerFunctionalUnitType) -> String {
        switch type {
        case .flatbed: return "flatbed"
        case .documentFeeder: return "document feeder (ADF)"
        case .negativeTransparency: return "negative transparency"
        case .positiveTransparency: return "positive transparency"
        @unknown default: return "unknown(\(type.rawValue))"
        }
    }

    private func selectSourceIfNeeded(scanner: ICScannerDevice, request: ScanRequest) async throws {
        let desiredType: ICScannerFunctionalUnitType?
        switch request.source {
        case .automatic:
            desiredType = nil
        case .flatbed:
            desiredType = .flatbed
        case .documentFeeder:
            desiredType = .documentFeeder
        }

        guard let desiredType else { return }

        let available = scanner.availableFunctionalUnitTypes.compactMap {
            ICScannerFunctionalUnitType(rawValue: UInt($0.uintValue))
        }
        guard available.contains(desiredType) else {
            let readable = request.source == .flatbed ? "flatbed" : "document feeder"
            throw ScannerBackendError.unavailable("The selected scanner does not provide a \(readable) source.")
        }

        if scanner.selectedFunctionalUnit.type == desiredType {
            return
        }

        try await withCheckedThrowingContinuation { continuation in
            selectionScanner = scanner
            selectionContinuation = continuation
            scanner.requestSelect(desiredType)
        }
    }

    private func configure(scanner: ICScannerDevice, request: ScanRequest) throws {
        scanner.transferMode = .fileBased
        scanner.downloadsDirectory = FileManager.default.temporaryDirectory
        scanner.documentName = "amurweb-scan-capture-\(UUID().uuidString)"
        scanner.documentUTI = UTType.png.identifier

        let unit = scanner.selectedFunctionalUnit
        unit.resolution = bestResolution(request.dpi, supported: unit.supportedResolutions, fallback: unit.resolution)

        switch request.colorMode {
        case .color:
            unit.pixelDataType = .RGB
        case .grayscale:
            unit.pixelDataType = .gray
        case .blackAndWhite:
            unit.pixelDataType = .BW
        }

        if let feeder = unit as? ICScannerFunctionalUnitDocumentFeeder {
            feeder.duplexScanningEnabled = request.duplexEnabled && feeder.supportsDuplexScanning
        }
    }

    private func bestResolution(_ requested: Int, supported: IndexSet, fallback: Int) -> Int {
        guard !supported.isEmpty else { return requested > 0 ? requested : fallback }
        if supported.contains(requested) { return requested }
        return supported.min(by: { abs($0 - requested) < abs($1 - requested) }) ?? fallback
    }

    private func finishHardwareScan(error: Error?) {
        guard let continuation = scanContinuation else {
            clearActiveScan()
            return
        }

        if let error {
            continuation.resume(throwing: error)
            cleanupTemporaryScans()
            clearActiveScan()
            return
        }

        guard let request = activeRequest, !scannedURLs.isEmpty else {
            continuation.resume(throwing: ScannerBackendError.scanFailed("The scanner completed without returning a file."))
            cleanupTemporaryScans()
            clearActiveScan()
            return
        }

        do {
            let outputURLs: [URL]

            if request.format == .pdf {
                let outputURL = namer.nextFileURL(
                    in: request.outputFolder,
                    format: .pdf,
                    language: request.language
                )
                try ImageOutputWriter.convert(sourceURLs: scannedURLs, to: outputURL, format: .pdf)
                outputURLs = [outputURL]
            } else {
                var pages: [URL] = []
                for sourceURL in scannedURLs {
                    let outputURL = namer.nextFileURL(
                        in: request.outputFolder,
                        format: request.format,
                        language: request.language
                    )
                    try ImageOutputWriter.convert(sourceURL: sourceURL, to: outputURL, format: request.format)
                    pages.append(outputURL)
                }
                outputURLs = pages
            }

            continuation.resume(returning: ScanResult(fileURLs: outputURLs, deviceName: request.device.name))
        } catch {
            continuation.resume(throwing: error)
        }

        cleanupTemporaryScans()
        clearActiveScan()
    }

    private func cleanupTemporaryScans() {
        for url in scannedURLs {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func clearActiveScan() {
        scanContinuation = nil
        activeRequest = nil
        activeScanner = nil
        scannedURLs.removeAll()

        if let continuation = selectionContinuation {
            continuation.resume(throwing: ScannerBackendError.scanFailed("Scan source selection was interrupted."))
        }
        selectionContinuation = nil
        selectionScanner = nil
    }

    func deviceBrowser(_ browser: ICDeviceBrowser, didAdd device: ICDevice, moreComing: Bool) {
        guard let scanner = device as? ICScannerDevice else { return }
        scanner.delegate = self
        scanners[stableID(for: scanner)] = scanner
    }

    func deviceBrowser(_ browser: ICDeviceBrowser, didRemove device: ICDevice, moreGoing: Bool) {
        guard let scanner = device as? ICScannerDevice else { return }
        let id = stableID(for: scanner)
        scanners[id] = nil
        scanner.delegate = nil

        if selectionScanner === scanner, let continuation = selectionContinuation {
            selectionContinuation = nil
            selectionScanner = nil
            continuation.resume(throwing: ScannerBackendError.scanFailed("The scanner was disconnected while selecting a scan source."))
        }

        if activeScanner === scanner {
            finishHardwareScan(error: ScannerBackendError.scanFailed("The scanner was disconnected during scanning."))
        }
    }

    func device(_ device: ICDevice, didOpenSessionWithError error: Error?) {
        if let scanner = device as? ICScannerDevice, let error, activeScanner === scanner {
            finishHardwareScan(error: error)
        }
    }

    func device(_ device: ICDevice, didCloseSessionWithError error: Error?) {
        if let scanner = device as? ICScannerDevice, let error, activeScanner === scanner {
            finishHardwareScan(error: error)
        }
    }

    func didRemove(_ device: ICDevice) {
        guard let scanner = device as? ICScannerDevice else { return }
        scanners[stableID(for: scanner)] = nil
    }

    func scannerDeviceDidBecomeAvailable(_ scanner: ICScannerDevice) {
        scanner.delegate = self
        scanners[stableID(for: scanner)] = scanner
    }

    func scannerDevice(_ scanner: ICScannerDevice, didSelect functionalUnit: ICScannerFunctionalUnit, error: Error?) {
        if selectionScanner === scanner, let continuation = selectionContinuation {
            selectionContinuation = nil
            selectionScanner = nil
            if let error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume()
            }
            return
        }

        if let error, activeScanner === scanner {
            finishHardwareScan(error: error)
        }
    }

    func scannerDevice(_ scanner: ICScannerDevice, didScanTo url: URL) {
        guard activeScanner === scanner else { return }
        scannedURLs.append(url)
    }

    func scannerDevice(_ scanner: ICScannerDevice, didCompleteScanWithError error: Error?) {
        guard activeScanner === scanner else { return }
        finishHardwareScan(error: error)
    }
}
