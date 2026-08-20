import Foundation

public enum AppLanguage: String, CaseIterable, Codable, Sendable {
    case ru
    case en
}

public enum ScanFormat: String, CaseIterable, Codable, Identifiable, Sendable {
    case jpg
    case png
    case pdf

    public var id: String { rawValue }
    public var fileExtension: String { rawValue }
}

public enum ScanColorMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case color
    case grayscale
    case blackAndWhite

    public var id: String { rawValue }
}

public enum ScanSource: String, CaseIterable, Codable, Identifiable, Sendable {
    case automatic
    case flatbed
    case documentFeeder

    public var id: String { rawValue }
}

public struct ScannerDevice: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let isMock: Bool
    public let supportedSources: [ScanSource]
    public let reportedResolutions: [Int]
    public let supportsDuplex: Bool?

    public init(
        id: String,
        name: String,
        isMock: Bool = false,
        supportedSources: [ScanSource] = [.automatic, .flatbed, .documentFeeder],
        reportedResolutions: [Int] = [150, 200, 300, 600],
        supportsDuplex: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.isMock = isMock
        self.supportedSources = supportedSources
        self.reportedResolutions = reportedResolutions
        self.supportsDuplex = supportsDuplex
    }
}

public struct ScanRequest: Sendable {
    public let device: ScannerDevice
    public let dpi: Int
    public let colorMode: ScanColorMode
    public let format: ScanFormat
    public let source: ScanSource
    public let duplexEnabled: Bool
    public let outputFolder: URL
    public let language: AppLanguage

    public init(
        device: ScannerDevice,
        dpi: Int,
        colorMode: ScanColorMode,
        format: ScanFormat,
        source: ScanSource = .automatic,
        duplexEnabled: Bool = false,
        outputFolder: URL,
        language: AppLanguage
    ) {
        self.device = device
        self.dpi = dpi
        self.colorMode = colorMode
        self.format = format
        self.source = source
        self.duplexEnabled = duplexEnabled
        self.outputFolder = outputFolder
        self.language = language
    }
}

public struct ScanResult: Sendable {
    public let fileURLs: [URL]
    public let deviceName: String

    public var fileURL: URL { fileURLs[0] }

    public init(fileURLs: [URL], deviceName: String) {
        precondition(!fileURLs.isEmpty, "ScanResult requires at least one output file.")
        self.fileURLs = fileURLs
        self.deviceName = deviceName
    }

    public init(fileURL: URL, deviceName: String) {
        self.init(fileURLs: [fileURL], deviceName: deviceName)
    }
}

public enum ScannerBackendError: LocalizedError, Sendable {
    case noDevice
    case unavailable(String)
    case scanFailed(String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .noDevice:
            return "Scanner device is not selected."
        case .unavailable(let message), .scanFailed(let message):
            return message
        case .cancelled:
            return "Scanning was cancelled."
        }
    }
}
