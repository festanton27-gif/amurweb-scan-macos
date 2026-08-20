import AppKit
import CoreGraphics
import Foundation
import AMURWEBScanCore

@MainActor
enum ImageOutputWriter {
    static func write(image: NSImage, to url: URL, format: ScanFormat) throws {
        var proposed = NSRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &proposed, context: nil, hints: nil) else {
            throw ScannerBackendError.scanFailed("Unable to create image data.")
        }
        try write(cgImage: cgImage, to: url, format: format)
    }

    static func convert(sourceURL: URL, to outputURL: URL, format: ScanFormat) throws {
        guard let image = NSImage(contentsOf: sourceURL) else {
            throw ScannerBackendError.scanFailed("The scanned image could not be opened.")
        }
        try write(image: image, to: outputURL, format: format)
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
            var mediaBox = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
            guard let consumer = CGDataConsumer(url: url as CFURL),
                  let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
                throw ScannerBackendError.scanFailed("Unable to create PDF.")
            }
            context.beginPDFPage(nil)
            context.draw(cgImage, in: mediaBox)
            context.endPDFPage()
            context.closePDF()
        }
    }
}
