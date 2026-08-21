import Foundation

@MainActor
final class DiagnosticSessionTrace {
    static let shared = DiagnosticSessionTrace()

    private let startedAt = Date()
    private let maximumEntries = 160
    private var entries: [String] = []

    private init() {
        record("app_session_started")
    }

    func record(_ event: String, details: [String: String] = [:]) {
        let elapsed = max(0, Date().timeIntervalSince(startedAt))
        let safeEvent = sanitize(event)
        let safeDetails = details
            .sorted { $0.key < $1.key }
            .map { "\(sanitize($0.key))=\(sanitize($0.value))" }
            .joined(separator: " ")

        let prefix = String(format: "+%07.3fs", elapsed)
        let line = safeDetails.isEmpty
            ? "\(prefix) \(safeEvent)"
            : "\(prefix) \(safeEvent) \(safeDetails)"

        entries.append(line)
        if entries.count > maximumEntries {
            entries.removeFirst(entries.count - maximumEntries)
        }
    }

    func snapshot() -> String {
        entries.isEmpty ? "No session events recorded." : entries.joined(separator: "\n")
    }

    private func sanitize(_ value: String) -> String {
        var result = value
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")

        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }

        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.count > 180 {
            result = String(result.prefix(180)) + "…"
        }
        return result
    }
}
