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

public struct ScannerDevice: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let isMock: Bool

    public init(id: String, name: String, isMock: Bool = false) {
        self.id = id
        self.name = name
        self.isMock = isMock
    }
}

public struct ScanRequest: Sendable {
    public let device: ScannerDevice
    public let dpi: Int
    public let colorMode: ScanColorMode
    public let format: ScanFormat
    public let outputFolder: URL
    public let language: AppLanguage

    public init(device: ScannerDevice, dpi: Int, colorMode: ScanColorMode, format: ScanFormat, outputFolder: URL, language: AppLanguage) {
        self.device = device
        self.dpi = dpi
        self.colorMode = colorMode
        self.format = format
        self.outputFolder = outputFolder
        self.language = language
    }
}

public struct ScanResult: Sendable {
    public let fileURL: URL
    public let deviceName: String

    public init(fileURL: URL, deviceName: String) {
        self.fileURL = fileURL
        self.deviceName = deviceName
    }
}

public enum ScannerBackendError: LocalizedError, Sendable {
    case noDevice
    case unavailable(String)
    case scanFailed(String)

    public var errorDescription: String? {
        switch self {
        case .noDevice:
            return "Scanner device is not selected."
        case .unavailable(let message), .scanFailed(let message):
            return message
        }
    }
}
