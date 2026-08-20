import AppKit
import Foundation
import AMURWEBScanCore

@MainActor
final class ScanViewModel: ObservableObject {
    @Published var devices: [ScannerDevice] = []
    @Published var selectedDeviceID: String?
    @Published var isBusy = false
    @Published var statusKey = "status.mock"
    @Published var previewURL: URL?
    @Published var errorMessage: String?

    private let backend: any ScannerBackend
    private let namer = ScanFileNamer()

    init(backend: any ScannerBackend = MockScannerBackend()) {
        self.backend = backend
    }

    var selectedDevice: ScannerDevice? {
        devices.first(where: { $0.id == selectedDeviceID })
    }

    func refresh(settings: AppSettings) async {
        isBusy = true
        defer { isBusy = false }
        do {
            devices = try await backend.listDevices()
            if let remembered = settings.lastScannerID, devices.contains(where: { $0.id == remembered }) {
                selectedDeviceID = remembered
            } else {
                selectedDeviceID = devices.first?.id
            }
            settings.lastScannerID = selectedDeviceID
            statusKey = "status.mock"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func scan(settings: AppSettings) async {
        guard let device = selectedDevice else {
            errorMessage = ScannerBackendError.noDevice.localizedDescription
            return
        }
        guard let folder = settings.outputFolder else {
            return
        }

        isBusy = true
        statusKey = "status.scanning"
        defer { isBusy = false }

        do {
            let request = ScanRequest(
                device: device,
                dpi: settings.selectedDPI,
                colorMode: settings.colorMode,
                format: settings.format,
                outputFolder: folder,
                language: settings.language
            )
            let result = try await backend.scan(request)
            previewURL = result.fileURL
            statusKey = "status.saved"
        } catch {
            errorMessage = error.localizedDescription
            statusKey = "status.ready"
        }
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
}
