# AMURWEB Scan for macOS 0.9.0 Alpha

Native macOS branch of the free AMURWEB Scan document scanner.

## 0.9.0 Alpha

This build hardens the release pipeline before the first real Mac + scanner validation. Scanner acquisition through ImageCaptureCore is intentionally unchanged.

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
- update notifications and AMURWEB ecosystem promotions isolated from scanning;
- package version is derived from `AppMetadata` instead of being duplicated in the packaging script;
- visible Alpha version text follows `AppMetadata` automatically;
- Apple Silicon and Intel jobs assert their expected architectures;
- Universal packaging asserts both `arm64` and `x86_64`;
- release verification checks `Info.plist`, bundle version, bundle id, minimum macOS, codesign verification and SHA-256;
- CI mounts the completed DMG and verifies the packaged `.app`, Universal executable and `Applications` symlink;
- tester artifact contains DMG, SHA-256 and the versioned Russian tester guide.

Scanned documents remain local. Network access is limited to version metadata and the optional AMURWEB product catalog.

## Validation status

GitHub Actions validates compilation on Apple Silicon and Intel, Swift tests, privacy-filter tests, Universal packaging and the final DMG release structure. Physical scanner behavior still requires an external Mac + scanner test before Beta.

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

- `AMURWEB-Scan-macOS-0.9.0-Alpha-Universal.dmg`
- `AMURWEB-Scan-macOS-0.9.0-Tester-Guide-RU.md`
- `SHA256SUMS.txt`
