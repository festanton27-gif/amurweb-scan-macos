import Foundation

public struct ScanFileNamer: Sendable {
    public init() {}

    public func nextFileURL(
        in folder: URL,
        date: Date = Date(),
        format: ScanFormat,
        language: AppLanguage,
        fileManager: FileManager = .default
    ) -> URL {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let datePart = String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
        let prefix = language == .ru ? "Скан" : "Scan"

        let names = (try? fileManager.contentsOfDirectory(atPath: folder.path)) ?? []
        var maxNumber = 0

        for name in names {
            let stem = URL(fileURLWithPath: name).deletingPathExtension().lastPathComponent
            let parts = stem.components(separatedBy: " - ")
            guard parts.count == 3 else { continue }
            guard parts[0] == "Скан" || parts[0] == "Scan" else { continue }
            guard parts[1] == datePart else { continue }
            guard let number = Int(parts[2]) else { continue }
            maxNumber = max(maxNumber, number)
        }

        let fileName = String(format: "%@ - %@ - %03d.%@", prefix, datePart, maxNumber + 1, format.fileExtension)
        return folder.appendingPathComponent(fileName, isDirectory: false)
    }
}
