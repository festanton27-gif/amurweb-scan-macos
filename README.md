# AMURWEB Scan for macOS 0.7.0 Alpha

Native macOS branch of the free AMURWEB Scan document scanner.

## 0.7.0 Alpha

This build focuses on public-facing UI polish and external-test readiness without changing the ImageCaptureCore acquisition pipeline.

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
- scanner capability-aware source/DPI/duplex controls;
- Mock Flatbed and Mock ADF are now hidden by default;
- virtual test scanners can be explicitly enabled in Settings;
- clearer no-scanner state for normal users;
- latest scan can be revealed directly in Finder;
- Scanner diagnostics can be refreshed, copied or exported as a `.txt` report;
- Swift-side application version metadata is centralized in `AppMetadata`;
- Finder folder selection and persistent settings;
- update notifications from the AMURWEB endpoint, at most once per day;
- manual **Check for updates** command;
- AMURWEB ecosystem promotion schedule: first 10 launches without promotion, then repeating 5 launches with / 2 without;
- promotion catalog cached for 24 hours; no impression/click telemetry;
- unavailable update/promotion server never blocks scanning;
- Apple Silicon + Intel CI and Universal DMG packaging.

Scanned documents remain local. Network access is limited to version metadata and the optional AMURWEB product catalog.

## Validation status

GitHub Actions validates Apple Silicon and Intel compilation, Swift tests and Universal DMG packaging. Physical scanner behavior still requires an external Mac + scanner test before Beta.

The Alpha uses ad-hoc signing. Stable public distribution will require Developer ID signing and Apple notarization.

## Build

```bash
swift test
swift build -c release
```

GitHub Actions creates:

`AMURWEB-Scan-macOS-0.7.0-Alpha-Universal.dmg`
