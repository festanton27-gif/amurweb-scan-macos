# AMURWEB Scan for macOS 0.6.0 Alpha

Native macOS branch of the free AMURWEB Scan document scanner.

## 0.6.0 Alpha

This build closes another functional gap with the Windows edition by adding manual multi-page PDF scanning for ordinary flatbed scanners without an ADF.

Implemented:

- native SwiftUI interface for macOS 13+;
- Russian and English UI;
- real scanner discovery through ImageCaptureCore;
- Automatic / Flatbed / ADF source selection;
- manual multi-page PDF from a flatbed scanner: scan page → Next page → Finish → one PDF;
- Automatic source prefers Flatbed for the manual multi-page workflow when the scanner reports a flatbed unit;
- temporary page images are kept outside the selected document folder and deleted after the session;
- only the final PDF consumes the normal `Скан/Scan - YYYY-MM-DD - NNN` sequence;
- automatic multi-page ADF scanning remains unchanged;
- duplex request for supported ADF devices;
- sequential multi-page JPG/PNG output for ADF jobs;
- native scan cancellation;
- scanner capability-aware source/DPI/duplex controls;
- Scanner diagnostics window;
- Mock flatbed and Mock ADF;
- Finder folder selection and persistent settings;
- update notifications from the AMURWEB update endpoint, at most once per day;
- manual **Check for updates** command;
- automatic update checks can be disabled in Settings;
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

`AMURWEB-Scan-macOS-0.6.0-Alpha-Universal.dmg`
