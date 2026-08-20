import AppKit
import CoreGraphics
import Foundation
import AMURWEBScanCore

@MainActor
enum ImageOutputWriter {
    static func write(image: NSImage, to url: URL, format: ScanFormat) throws {
        guard let cgImage = cgImage(from: image) else {
            throw ScannerBackendError.scanFailed("Unable to create image data.")
        }
        try write(cgImage: cgImage, to: url, format: format)
    }

    static func write(images: [NSImage], to url: URL, format: ScanFormat) throws {
        guard !images.isEmpty else {
            throw ScannerBackendError.scanFailed("No scanned pages were returned.")
        }

        if format != .pdf {
            guard images.count == 1 else {
                throw ScannerBackendError.scanFailed("Multiple image pages must be written to separate files.")
            }
            try write(image: images[0], to: url, format: format)
            return
        }

        let pages = images.compactMap(cgImage(from:))
        guard pages.count == images.count else {
            throw ScannerBackendError.scanFailed("One or more scanned pages could not be decoded.")
        }
        try writePDF(pages: pages, to: url)
    }

    static func convert(sourceURL: URL, to outputURL: URL, format: ScanFormat) throws {
        try convert(sourceURLs: [sourceURL], to: outputURL, format: format)
    }

    static func convert(sourceURLs: [URL], to outputURL: URL, format: ScanFormat) throws {
        guard !sourceURLs.isEmpty else {
            throw ScannerBackendError.scanFailed("The scanner completed without returning a file.")
        }

        let images = try sourceURLs.map { sourceURL -> NSImage in
            guard let image = NSImage(contentsOf: sourceURL) else {
                throw ScannerBackendError.scanFailed("The scanned image could not be opened.")
            }
            return image
        }

        if format == .pdf {
            try write(images: images, to: outputURL, format: .pdf)
        } else {
            guard images.count == 1 else {
                throw ScannerBackendError.scanFailed("Multiple scanned pages require separate image files.")
            }
            try write(image: images[0], to: outputURL, format: format)
        }
    }

    private static func cgImage(from image: NSImage) -> CGImage? {
        var proposed = NSRect(origin: .zero, size: image.size)
        return image.cgImage(forProposedRect: &proposed, context: nil, hints: nil)
    }

    private static func write(cgImage: CGImage, to url: URL, format: ScanFormat) throws {
        switch format {
        case .jpg, .png:
            let bitmap = NSBitmapImageRep(cgImage: cgImage)
            let type: NSBitmapImageRep.FileType = format == .jpg ? .jpeg : .png
            let properties: [NSBitmapImageRep.PropertyKey: Any] = format == .jpg ? [.compressionFactor: 0.92] : [:]
            guard let data = bitmap.representation(using: type, properties: properties) else {
                throw ScannerBackendError.scanFailed("Unable to encode image.")
            }
            try data.write(to: url, options: .atomic)

        case .pdf:
            try writePDF(pages: [cgImage], to: url)
        }
    }

    private static func writePDF(pages: [CGImage], to url: URL) throws {
        guard let first = pages.first else {
            throw ScannerBackendError.scanFailed("No pages are available for PDF output.")
        }

        var firstBox = CGRect(x: 0, y: 0, width: first.width, height: first.height)
        guard let consumer = CGDataConsumer(url: url as CFURL),
              let context = CGContext(consumer: consumer, mediaBox: &firstBox, nil) else {
            throw ScannerBackendError.scanFailed("Unable to create PDF.")
        }

        for page in pages {
            var mediaBox = CGRect(x: 0, y: 0, width: page.width, height: page.height)
            let pageInfo = [kCGPDFContextMediaBox as String: NSData(bytes: &mediaBox, length: MemoryLayout<CGRect>.size)] as CFDictionary
            context.beginPDFPage(pageInfo)
            context.draw(page, in: mediaBox)
            context.endPDFPage()
        }
        context.closePDF()
    }
}
