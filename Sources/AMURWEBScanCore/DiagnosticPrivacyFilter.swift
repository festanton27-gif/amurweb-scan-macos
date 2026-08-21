import Foundation

public enum DiagnosticPrivacyFilter {
    public static func sanitize(_ report: String) -> String {
        report
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { line in
                let text = String(line)
                if text.hasPrefix("ID: ") {
                    return "ID: redacted"
                }
                return text
            }
            .joined(separator: "\n")
    }
}
