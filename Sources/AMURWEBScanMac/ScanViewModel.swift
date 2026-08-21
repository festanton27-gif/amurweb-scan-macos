import AppKit
import Foundation
import UniformTypeIdentifiers
import AMURWEBScanCore

@MainActor
final class ScanViewModel: ObservableObject {
    @Published var devices: [ScannerDevice] = []
    @Published var selectedDeviceID: String?
    @Published var isBusy = false
    @Published var isCancelling = false
    @Published var statusKey = "status.ready"
    @Published var previewURL: URL?
    @Published var lastOutputURLs: [URL] = []
    @Published var diagnosticText = ""
    @Published var diagnosticsBusy = false
    @Published var errorMessage: String?

    private let backend: any ScannerBackend
    private let namer = ScanFileNamer()

    init() {
        self.backend = ScannerHubBackend()
    }

    init(backend: any ScannerBackend) {
        self.backend = backend
    }

    var selectedDevice: ScannerDevice? {
        devices.first(where: { $0.id == selectedDeviceID })
    }

    func refresh(settings: AppSettings) async {
        isBusy = true
        defer { isBusy = false }
        do {
            let discovered = try await backend.listDevices()
            devices = ScannerVisibilityPolicy.visibleDevices(
                from: discovered,
                includeTestDevices: settings.showTestScanners
            )

            if let remembered = settings.lastScannerID,
               devices.contains(where: { $0.id == remembered }) {
                selectedDeviceID = remembered
            } else {
                selectedDeviceID = devices.first?.id
            }

            settings.lastScannerID = selectedDeviceID
            if let selectedDevice {
                statusKey = selectedDevice.isMock ? "status.mock" : "status.hardware"
            } else {
                statusKey = "status.noScanner"
            }
        } catch {
            devices = []
            selectedDeviceID = nil
            settings.lastScannerID = nil
            statusKey = "status.noScanner"
            errorMessage = friendlyError(error, language: settings.language)
        }
    }

    func refreshDiagnostics() async {
        diagnosticsBusy = true
        diagnosticText = await backend.diagnosticReport()
        diagnosticsBusy = false
    }

    func copyDiagnostics() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(diagnosticText, forType: .string)
    }

    func saveDiagnostics(settings: AppSettings) {
        guard !diagnosticText.isEmpty else { return }

        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "AMURWEB-Scan-Diagnostics-\(AppMetadata.version).txt"
        panel.title = settings.t("diagnostics.save")
        panel.prompt = settings.t("diagnostics.saveButton")

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try diagnosticText.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            errorMessage = settings.t("diagnostics.saveError") + "\n\n" + error.localizedDescription
        }
    }

    func scan(settings: AppSettings) async {
        guard let device = selectedDevice else {
            errorMessage = settings.t("error.noDevice")
            return
        }
        guard let folder = settings.outputFolder else {
            errorMessage = settings.t("error.noFolder")
            return
        }

        isBusy = true
        isCancelling = false
        statusKey = "status.scanning"
        defer {
            isBusy = false
            isCancelling = false
        }

        do {
            if settings.manualMultiPagePDF,
               settings.format == .pdf,
               settings.scanSource != .documentFeeder {
                try await scanManualMultiPagePDF(
                    device: device,
                    outputFolder: folder,
                    settings: settings
                )
            } else {
                let request = ScanRequest(
                    device: device,
                    dpi: settings.selectedDPI,
                    colorMode: settings.colorMode,
                    format: settings.format,
                    source: settings.scanSource,
                    duplexEnabled: settings.duplexEnabled,
                    outputFolder: folder,
                    language: settings.language
                )
                let result = try await backend.scan(request)
                lastOutputURLs = result.fileURLs
                previewURL = result.fileURLs.first
            }
            statusKey = "status.saved"
        } catch ScannerBackendError.cancelled {
            errorMessage = nil
            statusKey = "status.cancelled"
        } catch is CancellationError {
            errorMessage = nil
            statusKey = "status.cancelled"
        } catch {
            errorMessage = friendlyError(error, language: settings.language)
            if let selectedDevice {
                statusKey = selectedDevice.isMock ? "status.mock" : "status.hardware"
            } else {
                statusKey = "status.noScanner"
            }
        }
    }

    private func scanManualMultiPagePDF(
        device: ScannerDevice,
        outputFolder: URL,
        settings: AppSettings
    ) async throws {
        let sessionFolder = FileManager.default.temporaryDirectory
            .appendingPathComponent("amurweb-scan-manual-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: sessionFolder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: sessionFolder) }

        var pageFiles: [URL] = []
        let manualSource: ScanSource =
            settings.scanSource == .automatic && device.supportedSources.contains(.flatbed)
            ? .flatbed
            : settings.scanSource

        while true {
            let request = ScanRequest(
                device: device,
                dpi: settings.selectedDPI,
                colorMode: settings.colorMode,
                format: .png,
                source: manualSource,
                duplexEnabled: false,
                outputFolder: sessionFolder,
                language: settings.language
            )

            let result = try await backend.scan(request)
            guard !result.fileURLs.isEmpty else {
                throw ScannerBackendError.scanFailed("The scanner returned no page for the manual multi-page document.")
            }
            pageFiles.append(contentsOf: result.fileURLs)

            switch nextPageDecision(pageCount: pageFiles.count, settings: settings) {
            case .scanNext:
                statusKey = "status.scanning"
                continue
            case .finish:
                let outputURL = namer.nextFileURL(
                    in: outputFolder,
                    format: .pdf,
                    language: settings.language
                )
                try ImageOutputWriter.convert(sourceURLs: pageFiles, to: outputURL, format: .pdf)
                lastOutputURLs = [outputURL]
                previewURL = outputURL
                return
            case .cancel:
                throw ScannerBackendError.cancelled
            }
        }
    }

    private enum ManualPageDecision {
        case scanNext
        case finish
        case cancel
    }

    private func nextPageDecision(pageCount: Int, settings: AppSettings) -> ManualPageDecision {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = String(format: settings.t("multipage.pageScanned"), pageCount)
        alert.informativeText = settings.t("multipage.nextPrompt")
        alert.addButton(withTitle: settings.t("multipage.next"))
        alert.addButton(withTitle: settings.t("multipage.finish"))
        alert.addButton(withTitle: settings.t("cancel"))

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            return .scanNext
        case .alertSecondButtonReturn:
            return .finish
        default:
            return .cancel
        }
    }

    func cancelScan() {
        guard isBusy, !isCancelling else { return }
        isCancelling = true
        statusKey = "status.cancelling"
        backend.cancelScan()
    }

    func nextFileName(settings: AppSettings) -> String {
        guard let folder = settings.outputFolder else { return "—" }
        return namer.nextFileURL(in: folder, format: settings.format, language: settings.language).lastPathComponent
    }

    func chooseFolder(settings: AppSettings) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = settings.language == .ru ? "Выбрать" : "Choose"
        panel.message = settings.t("choose.folder")
        panel.directoryURL = settings.outputFolder

        if panel.runModal() == .OK, let url = panel.url {
            settings.outputFolder = url
        }
    }

    func openOutputFolder(settings: AppSettings) {
        guard let folder = settings.outputFolder else { return }
        NSWorkspace.shared.open(folder)
    }

    func revealLastOutput() {
        guard !lastOutputURLs.isEmpty else { return }
        NSWorkspace.shared.activateFileViewerSelecting(lastOutputURLs)
    }

    private func friendlyError(_ error: Error, language: AppLanguage) -> String {
        let t: (String) -> String = { L10n.text($0, language: language) }

        if let backendError = error as? ScannerBackendError {
            switch backendError {
            case .noDevice:
                return t("error.noDevice")
            case .cancelled:
                return t("status.cancelled")
            case .unavailable(let detail):
                return t("error.unsupported") + "\n\n" + detail
            case .scanFailed(let detail):
                return t("error.scanFailed") + "\n\n" + detail
            }
        }

        let nsError = error as NSError
        return t("error.scanFailed") + "\n\n" + error.localizedDescription + "\n[\(nsError.domain) · \(nsError.code)]"
    }
}
