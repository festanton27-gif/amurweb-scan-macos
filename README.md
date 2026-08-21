# AMURWEB Scan for macOS 1.0.0 RC1

Native macOS edition of the free AMURWEB Scan document scanner.

## 1.0.0 RC1

This is the feature-frozen release candidate for the first Stable macOS release. No new scanner features are planned between RC1 and Stable; only issues found during final hardware validation or release signing may be fixed.

Implemented:

- native SwiftUI interface for macOS 13+;
- Russian and English UI;
- scanner discovery and acquisition through Apple ImageCaptureCore;
- Automatic / Flatbed / ADF source selection;
- JPG, PNG and PDF output;
- manual multi-page PDF from an ordinary flatbed scanner without ADF;
- automatic multi-page PDF from ADF jobs;
- sequential multi-page JPG/PNG output for ADF jobs;
- duplex request when reported by the selected feeder;
- native scan cancellation;
- Finder folder selection, persistent settings and sequential file naming;
- Mock scanners hidden by default and available only through explicit test mode;
- Finder reveal for the latest scan result;
- privacy-conscious support report with persistent scanner IDs redacted;
- in-memory current-run diagnostic session trace without document contents or paths;
- update notifications from the AMURWEB endpoint;
- AMURWEB ecosystem promotion cycle: first 10 launches without promotion, then repeating 5 with / 2 without;
- no impression/click telemetry;
- Apple Silicon and Intel builds combined into one Universal application;
- release verification for architectures, Info.plist, signature, SHA-256 and mounted DMG contents.

Scanned documents remain local. Network access is limited to version metadata and the optional AMURWEB product catalog.

## Stable gate

RC1 is code-complete. Two external checks remain before the public Stable label:

1. A real Mac + physical scanner must complete the external hardware checklist, including single-page scans, manual flatbed multi-page PDF, cancellation, and ADF/duplex where the test scanner supports them.
2. Public distribution must use a Developer ID Application signature and Apple notarization. The packaging script supports Developer ID through `DEVELOPER_ID_APPLICATION`; `scripts/notarize-release.sh` performs `notarytool`, stapling and Gatekeeper verification once Apple credentials are configured.

RC/testing builds fall back to an ad-hoc signature when Developer ID is not configured. Do not disable Gatekeeper globally for testing.

## Build

```bash
swift test
swift build -c release
```

Universal packaging:

```bash
bash scripts/package-universal.sh "$PWD/build/AMURWEBScanMac" "$PWD/dist"
bash scripts/verify-release.sh "$PWD/dist"
```

For a Developer ID build set `DEVELOPER_ID_APPLICATION` before packaging. After configuring a `notarytool` keychain profile, set `NOTARYTOOL_PROFILE` and run:

```bash
bash scripts/notarize-release.sh "$PWD/dist"
```

GitHub Actions creates the RC tester artifact containing:

- `AMURWEB-Scan-macOS-1.0.0-RC1-Universal.dmg`
- `AMURWEB-Scan-macOS-1.0.0-Tester-Guide-RU.md`
- `SHA256SUMS.txt`
