import Foundation
import ImageCaptureCore
import UniformTypeIdentifiers
import AMURWEBScanCore

@MainActor
final class ImageCaptureScannerBackend: NSObject, ScannerBackend, ICDeviceBrowserDelegate, ICScannerDeviceDelegate {
    let backendName = "ImageCaptureCore"

    private let browser = ICDeviceBrowser()
    private var browserStarted = false
    private var scanners: [String: ICScannerDevice] = [:]
    private var activeRequest: ScanRequest?
    private var activeScanner: ICScannerDevice?
    private var scannedURLs: [URL] = []
    private var scanContinuation: CheckedContinuation<ScanResult, Error>?
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

    func scan(_ request: ScanRequest) async throws -> ScanResult {
        guard scanContinuation == nil else {
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
        browser.browsedDeviceTypeMask = ICDeviceTypeMask(rawValue: rawMask)
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

    private func configure(scanner: ICScannerDevice, request: ScanRequest) throws {
        scanner.transferMode = .fileBased
        scanner.downloadsDirectory = FileManager.default.temporaryDirectory
        scanner.documentName = "amurweb-scan-capture-\(UUID().uuidString)"
        scanner.documentUTI = UTType.png.identifier

        guard let unit = scanner.selectedFunctionalUnit else {
            throw ScannerBackendError.scanFailed("The scanner did not provide a selectable scan unit.")
        }
        unit.resolution = bestResolution(request.dpi, supported: unit.supportedResolutions, fallback: unit.resolution)

        switch request.colorMode {
        case .color:
            unit.pixelDataType = .RGB
        case .grayscale:
            unit.pixelDataType = .gray
        case .blackAndWhite:
            unit.pixelDataType = .BW
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
            clearActiveScan()
            return
        }

        guard let request = activeRequest, let sourceURL = scannedURLs.first else {
            continuation.resume(throwing: ScannerBackendError.scanFailed("The scanner completed without returning a file."))
            clearActiveScan()
            return
        }

        do {
            let outputURL = namer.nextFileURL(
                in: request.outputFolder,
                format: request.format,
                language: request.language
            )
            try ImageOutputWriter.convert(sourceURL: sourceURL, to: outputURL, format: request.format)
            continuation.resume(returning: ScanResult(fileURL: outputURL, deviceName: request.device.name))
        } catch {
            continuation.resume(throwing: error)
        }

        for url in scannedURLs {
            try? FileManager.default.removeItem(at: url)
        }
        clearActiveScan()
    }

    private func clearActiveScan() {
        scanContinuation = nil
        activeRequest = nil
        activeScanner = nil
        scannedURLs.removeAll()
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
