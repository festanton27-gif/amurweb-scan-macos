import Foundation

enum AppMetadata {
    static let version = "1.0.0"
    static let channel = "RC1"
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
