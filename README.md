# AMURWEB Scan for macOS 0.5.0 Alpha

Native macOS branch of the free AMURWEB Scan document scanner.

## 0.5.0 Alpha

This build keeps the 0.4 scanner pipeline intact and adds lightweight ecosystem services around it.

Implemented:

- native SwiftUI interface for macOS 13+;
- Russian and English UI;
- real scanner discovery through ImageCaptureCore;
- Automatic / Flatbed / ADF source selection;
- duplex request for supported ADF devices;
- multi-page ADF scanning;
- multi-page PDF;
- sequential multi-page JPG/PNG output;
- native scan cancellation;
- scanner capability-aware source/DPI/duplex controls;
- Scanner diagnostics window;
- Mock flatbed and Mock ADF;
- Finder folder selection and persistent settings;
- update notifications from the AMURWEB update endpoint, at most once per day;
- manual **Check for updates** command;
- automatic update checks can be disabled in Settings;
- AMURWEB ecosystem promotion schedule: first 10 launches without promotion, then repeating 5 launches with / 2 without;
- launch counter remains local;
- promotion catalog cached for 24 hours;
- no impression/click telemetry;
- unavailable update/promotion server never blocks scanning;
- Apple Silicon + Intel CI and Universal DMG packaging.

Scanned documents remain local. Network access in 0.5.0 is limited to version metadata and the optional AMURWEB product catalog.

## Validation status

GitHub Actions validates Apple Silicon and Intel compilation, Swift tests and Universal DMG packaging. Physical scanner behavior still requires an external Mac + scanner test before Beta.

The Alpha uses ad-hoc signing. Stable public distribution will require Developer ID signing and Apple notarization.

## Build

```bash
swift test
swift build -c release
```

GitHub Actions creates:

`AMURWEB-Scan-macOS-0.5.0-Alpha-Universal.dmg`
