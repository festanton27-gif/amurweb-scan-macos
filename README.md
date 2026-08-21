# AMURWEB Scan for macOS 0.10.0 Alpha

Native macOS branch of the free AMURWEB Scan document scanner.

## 0.10.0 Alpha

This build improves real-hardware troubleshooting before Beta without changing the ImageCaptureCore acquisition pipeline.

Implemented and retained:

- native SwiftUI interface for macOS 13+;
- Russian and English UI;
- real scanner discovery through ImageCaptureCore;
- Automatic / Flatbed / ADF source selection;
- manual multi-page PDF from an ordinary flatbed scanner;
- automatic multi-page PDF from ADF jobs;
- duplex request for supported ADF devices;
- sequential multi-page JPG/PNG output for ADF jobs;
- native scan cancellation;
- Mock scanners hidden by default with an explicit Settings opt-in;
- clear no-scanner state and Finder reveal for the latest result;
- privacy-conscious support report with persistent scanner IDs redacted;
- new in-memory session trace for the current application run;
- trace records device refresh, safe hardware discovery errors, scan start/completion, output count, cancellation request and diagnostics generation;
- trace scan details are limited to scanner display name, mock/hardware kind, source, DPI, format and duplex;
- error trace stores only error domain and numeric code, not localized error text or file paths;
- trace is capped at 160 entries, is not persisted between launches and is included only when the user views/copies/saves the support report;
- release notice text is generated from current `AppMetadata` rather than an old version string in localization resources;
- update notifications and AMURWEB ecosystem promotions remain isolated from scanning;
- hardened release pipeline from 0.9.0 remains active: architecture assertions, synchronized version checks, `Info.plist`, codesign, SHA-256 and mounted-DMG validation;
- tester artifact contains DMG, SHA-256 and the versioned Russian tester guide.

Scanned documents remain local. Network access is limited to version metadata and the optional AMURWEB product catalog.

## Validation status

GitHub Actions validates compilation on Apple Silicon and Intel, Swift tests, privacy-filter tests, Universal packaging and the final DMG release structure. The session trace is compiled on both architectures, but physical scanner behavior still requires an external Mac + scanner test before Beta.

The Alpha uses ad-hoc signing. Stable public distribution will require Developer ID signing and Apple notarization. Do not disable Gatekeeper globally for Alpha testing.

## Build

```bash
swift test
swift build -c release
```

The Universal CI job additionally runs:

```bash
bash scripts/verify-release.sh "$PWD/dist"
```

GitHub Actions creates the tester artifact containing:

- `AMURWEB-Scan-macOS-0.10.0-Alpha-Universal.dmg`
- `AMURWEB-Scan-macOS-0.10.0-Tester-Guide-RU.md`
- `SHA256SUMS.txt`
