import Foundation

enum AppMetadata {
    static let version = "0.10.0"
    static let channel = "Alpha"
    static let platform = "macOS"

    static var displayVersion: String {
        "\(version) \(channel)"
    }

    static var fullDisplayVersion: String {
        "\(displayVersion) · \(platform)"
    }

    static var userAgent: String {
        "AMURWEB Scan macOS/\(version)"
    }
}
