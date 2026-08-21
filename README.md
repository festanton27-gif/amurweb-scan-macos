# AMURWEB Scan for macOS 0.8.0 Alpha

Native macOS branch of the free AMURWEB Scan document scanner.

## 0.8.0 Alpha

This build prepares AMURWEB Scan for a real external Mac + scanner test without changing the ImageCaptureCore acquisition pipeline.

Implemented:

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
- one privacy-conscious support report containing app version, macOS, architecture, scan settings and scanner capabilities;
- persistent scanner identifiers are redacted from the support report;
- support report excludes scan contents, scan file names and document/output-folder paths;
- Core unit tests verify scanner-ID redaction;
- support report can be copied or saved as UTF-8 text;
- update notifications and AMURWEB ecosystem promotions remain isolated from scanning;
- Universal artifact now contains the DMG, SHA-256 file and a versioned Russian tester guide;
- Apple Silicon + Intel CI and Universal DMG packaging.

Scanned documents remain local. Network access is limited to version metadata and the optional AMURWEB product catalog.

## Validation status

GitHub Actions validates Apple Silicon and Intel compilation, Swift tests, privacy-filter tests and Universal DMG packaging. Physical scanner behavior still requires an external Mac + scanner test before Beta.

The Alpha uses ad-hoc signing. Stable public distribution will require Developer ID signing and Apple notarization.

## Build

```bash
swift test
swift build -c release
```

GitHub Actions creates the tester artifact containing:

- `AMURWEB-Scan-macOS-0.8.0-Alpha-Universal.dmg`
- `AMURWEB-Scan-macOS-0.8.0-Tester-Guide-RU.md`
- `SHA256SUMS.txt`
