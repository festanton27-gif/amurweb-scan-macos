# AMURWEB Scan for macOS 0.3.0 Alpha

Native macOS branch of the free AMURWEB Scan document scanner.

## 0.3.0 Alpha

This build expands the ImageCaptureCore hardware layer beyond a single flat scan and prepares the app for real-world scanner testing.

Implemented:

- native SwiftUI interface for macOS 13+;
- Russian and English UI;
- real scanner discovery using `ICDeviceBrowser`;
- real scan requests using `ICScannerDevice`;
- source selection: Automatic / Flatbed / Document Feeder (ADF);
- duplex request for ADF devices that report duplex support;
- multi-page ADF handling;
- multi-page PDF output from one feeder job;
- sequential JPG/PNG files for multi-page image output;
- diagnostic Mock Scanner with virtual flatbed and multi-page ADF;
- scanner diagnostics window for support reports;
- Finder folder selection;
- 150 / 200 / 300 / 600 DPI request with nearest supported fallback;
- color, grayscale and B&W scan modes;
- JPG, PNG and PDF output;
- automatic `Скан/Scan - YYYY-MM-DD - 001` naming;
- settings persistence;
- preview;
- About / Support / Diagnostics / Legal windows;
- AMURWEB company and product branding;
- Apple Silicon + Intel CI and Universal DMG packaging.

## Hardware validation warning

The project owner does not currently have a physical Mac. GitHub Actions verifies compilation on real macOS runners for both Apple Silicon and Intel, but it cannot attach a USB scanner. Therefore **0.3.0 remains Alpha until an external real-Mac scanner test confirms discovery and scanning**.

The built-in **Scanner diagnostics** window is intended to make that external test useful: it reports which scanners ImageCaptureCore can see, available functional-unit types, current/supported DPI, and ADF/duplex information when the selected unit exposes it.

## Architecture

`ScannerHubBackend` combines:

- `ImageCaptureScannerBackend` — actual ImageCaptureCore hardware;
- `MockScannerBackend` — deterministic diagnostic scanner.

The app asks ImageCaptureCore for PNG pages in file-transfer mode, then converts them locally to the requested output. ADF scans can produce multiple files; PDF output combines all returned pages into one document.

## Build

```bash
swift test
swift build -c release
```

GitHub Actions creates:

`AMURWEB-Scan-macOS-0.3.0-Alpha-Universal.dmg`

The Alpha uses ad-hoc signing. Stable public distribution will require Developer ID signing and Apple notarization.
