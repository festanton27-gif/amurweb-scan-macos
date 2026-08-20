# AMURWEB Scan for macOS 0.4.0 Alpha

Native macOS branch of the free AMURWEB Scan document scanner.

## 0.4.0 Alpha

This build focuses on safer real-hardware behavior before external testing.

Implemented:

- native SwiftUI interface for macOS 13+;
- Russian and English UI;
- real scanner discovery through ImageCaptureCore;
- Automatic / Flatbed / ADF source selection;
- duplex request for supported ADF devices;
- multi-page ADF scanning;
- multi-page PDF;
- sequential multi-page JPG/PNG output;
- native scan cancellation through `ICScannerDevice.cancelScan()`;
- visible Cancel control while a job is active;
- scanner settings locked while scanning;
- scanner-reported capabilities used to adapt source/DPI/duplex controls;
- friendlier RU/EN scan errors while preserving technical details for support;
- Scanner diagnostics window;
- Mock flatbed and Mock ADF for CI-friendly functional testing;
- Finder folder selection and persistent settings;
- AMURWEB branding, About, Support and Legal windows;
- Apple Silicon + Intel CI and Universal DMG packaging.

## Validation status

GitHub Actions validates Apple Silicon and Intel compilation, Swift tests and Universal DMG packaging. Physical scanner behavior still requires an external Mac + scanner test before Beta.

The Alpha uses ad-hoc signing. Stable public distribution will require Developer ID signing and Apple notarization.

## Build

```bash
swift test
swift build -c release
```

GitHub Actions creates:

`AMURWEB-Scan-macOS-0.4.0-Alpha-Universal.dmg`
