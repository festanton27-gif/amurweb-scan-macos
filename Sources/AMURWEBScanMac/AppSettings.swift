import Foundation
import AMURWEBScanCore

@MainActor
final class AppSettings: ObservableObject {
    @Published var language: AppLanguage { didSet { defaults.set(language.rawValue, forKey: Keys.language) } }
    @Published var selectedDPI: Int { didSet { defaults.set(selectedDPI, forKey: Keys.dpi) } }
    @Published var colorMode: ScanColorMode { didSet { defaults.set(colorMode.rawValue, forKey: Keys.colorMode) } }
    @Published var format: ScanFormat { didSet { defaults.set(format.rawValue, forKey: Keys.format) } }
    @Published var scanSource: ScanSource { didSet { defaults.set(scanSource.rawValue, forKey: Keys.scanSource) } }
    @Published var duplexEnabled: Bool { didSet { defaults.set(duplexEnabled, forKey: Keys.duplex) } }
    @Published var outputFolder: URL? { didSet { defaults.set(outputFolder?.path, forKey: Keys.folder) } }
    @Published var lastScannerID: String? { didSet { defaults.set(lastScannerID, forKey: Keys.scanner) } }

    private let defaults: UserDefaults

    private enum Keys {
        static let language = "language"
        static let dpi = "dpi"
        static let colorMode = "colorMode"
        static let format = "format"
        static let scanSource = "scanSource"
        static let duplex = "duplexEnabled"
        static let folder = "folder"
        static let scanner = "scanner"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let raw = defaults.string(forKey: Keys.language), let stored = AppLanguage(rawValue: raw) {
            language = stored
        } else {
            language = Locale.current.language.languageCode?.identifier.lowercased() == "ru" ? .ru : .en
        }

        let dpi = defaults.integer(forKey: Keys.dpi)
        selectedDPI = dpi > 0 ? dpi : 300

        colorMode = ScanColorMode(rawValue: defaults.string(forKey: Keys.colorMode) ?? "") ?? .color
        format = ScanFormat(rawValue: defaults.string(forKey: Keys.format) ?? "") ?? .jpg
        scanSource = ScanSource(rawValue: defaults.string(forKey: Keys.scanSource) ?? "") ?? .automatic
        duplexEnabled = defaults.bool(forKey: Keys.duplex)

        if let path = defaults.string(forKey: Keys.folder), FileManager.default.fileExists(atPath: path) {
            outputFolder = URL(fileURLWithPath: path, isDirectory: true)
        } else {
            outputFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        }

        lastScannerID = defaults.string(forKey: Keys.scanner)
    }

    func t(_ key: String) -> String {
        L10n.text(key, language: language)
    }
}
