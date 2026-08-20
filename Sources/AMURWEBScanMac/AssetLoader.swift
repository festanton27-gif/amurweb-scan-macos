import AppKit

func bundledImage(named name: String) -> NSImage? {
    if let url = Bundle.main.url(forResource: name, withExtension: "png") {
        return NSImage(contentsOf: url)
    }
    return nil
}
