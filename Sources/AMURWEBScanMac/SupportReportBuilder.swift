import Foundation
import AMURWEBScanCore

@MainActor
enum SupportReportBuilder {
    static func make(
        settings: AppSettings,
        selectedDevice: ScannerDevice?,
        backendReport: String
    ) -> String {
        var lines: [String] = [
            "AMURWEB Scan Support Report",
            "Generated: \(ISO8601DateFormatter().string(from: Date()))",
            "Application: \(AppMetadata.fullDisplayVersion)",
            "macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)",
            "Architecture: \(architecture)",
            "Interface language: \(settings.language.rawValue)",
            "",
            "Application settings",
            "DPI: \(settings.selectedDPI)",
            "Color mode: \(settings.colorMode.rawValue)",
            "Format: \(settings.format.rawValue.uppercased())",
            "Source: \(settings.scanSource.rawValue)",
            "Duplex requested: \(settings.duplexEnabled ? "yes" : "no")",
            "Manual multi-page PDF: \(settings.manualMultiPagePDF ? "yes" : "no")",
            "Output folder configured: \(settings.outputFolder == nil ? "no" : "yes")",
            "Automatic update checks: \(settings.automaticUpdateChecks ? "yes" : "no")",
            "Test scanners visible: \(settings.showTestScanners ? "yes" : "no")",
            ""
        ]

        if let device = selectedDevice {
            lines.append("Selected scanner")
            lines.append("Name: \(device.name)")
            lines.append("Test device: \(device.isMock ? "yes" : "no")")
            lines.append("Reported sources: \(device.supportedSources.map(\.rawValue).joined(separator: ", "))")
            lines.append("Reported resolutions: \(device.reportedResolutions.map(String.init).joined(separator: ", "))")
            if let duplex = device.supportsDuplex {
                lines.append("Reported duplex: \(duplex ? "yes" : "no")")
            } else {
                lines.append("Reported duplex: unknown")
            }
            lines.append("")
        } else {
            lines.append("Selected scanner: none")
            lines.append("")
        }

        lines.append("Scanner backend diagnostics")
        lines.append(backendReport)
        lines.append("")
        lines.append("Privacy")
        lines.append("This report does not include scanned document contents, scan file names, document paths, or output-folder paths.")

        return lines.joined(separator: "\n")
    }

    private static var architecture: String {
        #if arch(arm64)
        return "arm64 (Apple Silicon)"
        #elseif arch(x86_64)
        return "x86_64 (Intel)"
        #else
        return "unknown"
        #endif
    }
}
