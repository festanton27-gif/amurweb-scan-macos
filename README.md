# AMURWEB Scan for macOS 0.2.0 Alpha

Native macOS branch of the free AMURWEB Scan document scanner.

## 0.2.0 Alpha

This build introduces the first real scanner transport through Apple's **ImageCaptureCore** framework.

Implemented:

- native SwiftUI interface for macOS 13+;
- Russian and English UI;
- real scanner discovery using `ICDeviceBrowser`;
- real scan requests using `ICScannerDevice`;
- diagnostic Mock Scanner remains available;
- Finder folder selection;
- 150 / 200 / 300 / 600 DPI request with nearest supported fallback;
- color, grayscale and B&W scan modes;
- JPG, PNG and one-page PDF output;
- automatic `Скан/Scan - YYYY-MM-DD - 001` naming;
- settings persistence;
- preview;
- About / Support / Legal windows;
- AMURWEB company and product branding;
- Apple Silicon + Intel CI and Universal DMG packaging.

## Hardware validation warning

The project owner does not currently have a physical Mac. GitHub Actions verifies compilation on real macOS runners for both Apple Silicon and Intel, but it cannot attach a USB scanner. Therefore **0.2.0 remains Alpha until at least one external real-Mac scanner test succeeds**.

## Architecture

`ScannerHubBackend` combines:

- `ImageCaptureScannerBackend` — actual ImageCaptureCore hardware;
- `MockScannerBackend` — deterministic diagnostic scanner.

The app asks ImageCaptureCore for a PNG scan in file-transfer mode, then converts the result locally to the user's requested JPG, PNG or PDF output.

## Build

```bash
swift test
swift build -c release
```

GitHub Actions creates:

`AMURWEB-Scan-macOS-0.2.0-Alpha-Universal.dmg`

The Alpha uses ad-hoc signing. Stable public distribution will require Developer ID signing and Apple notarization.
