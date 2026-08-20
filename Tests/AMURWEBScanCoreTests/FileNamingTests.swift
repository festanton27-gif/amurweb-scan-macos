import XCTest
@testable import AMURWEBScanCore

final class FileNamingTests: XCTestCase {
    func testStartsAt001() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        let date = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 8, day: 20, hour: 12))!
        let url = ScanFileNamer().nextFileURL(in: folder, date: date, format: .jpg, language: .ru)
        XCTAssertEqual(url.lastPathComponent, "Скан - 2026-08-20 - 001.jpg")
    }

    func testNumberContinuesAcrossFormatsAndLanguages() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        try Data().write(to: folder.appendingPathComponent("Скан - 2026-08-20 - 001.jpg"))
        try Data().write(to: folder.appendingPathComponent("Scan - 2026-08-20 - 002.pdf"))
        let date = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 8, day: 20, hour: 12))!
        let url = ScanFileNamer().nextFileURL(in: folder, date: date, format: .png, language: .en)
        XCTAssertEqual(url.lastPathComponent, "Scan - 2026-08-20 - 003.png")
    }

    func testNewFolderRestartsAt001() throws {
        let first = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let second = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: first, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: second, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: first)
            try? FileManager.default.removeItem(at: second)
        }

        try Data().write(to: first.appendingPathComponent("Скан - 2026-08-20 - 010.jpg"))
        let date = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 8, day: 20, hour: 12))!
        let url = ScanFileNamer().nextFileURL(in: second, date: date, format: .pdf, language: .ru)
        XCTAssertEqual(url.lastPathComponent, "Скан - 2026-08-20 - 001.pdf")
    }
}
