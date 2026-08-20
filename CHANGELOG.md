# Changelog

## 0.4.0 Alpha

- Added native scan cancellation through ImageCaptureCore and a visible Cancel control while scanning.
- Added cancellation support to Mock Scanner for hardware-independent UI testing.
- Scan settings are locked while a job is active to avoid mid-scan configuration changes.
- Added friendlier Russian and English error messages while retaining useful technical details for support.
- Scanner discovery now reports available sources, supported resolutions and duplex capability to the UI.
- Source selection adapts to the selected device instead of offering unsupported Flatbed/ADF modes blindly.
- Standard DPI choices are filtered using scanner-reported capabilities when available.
- Incompatible remembered source/DPI/duplex settings are normalized when changing devices.
- Scanner diagnostics and support text were retained and updated for the new capability-aware hardware layer.
- Updated About information and Universal DMG packaging to 0.4.0 Alpha.

### Validation status

Apple Silicon and Intel compilation, unit tests and Universal DMG packaging are verified through GitHub Actions. Physical scanner behavior still requires an external Mac + scanner test before Beta.

## 0.3.0 Alpha

- Added scan source selection: Automatic, Flatbed and Document Feeder (ADF).
- Added ADF duplex option; it is enabled only when the selected feeder reports duplex support.
- Added multi-page hardware scan handling for ImageCaptureCore feeder jobs.
- PDF output can now combine all pages returned by one ADF scan into a single multi-page PDF.
- JPG/PNG multi-page scans are saved as separate sequentially numbered image files.
- Upgraded Mock ADF to generate multi-page simplex and duplex jobs for hardware-independent testing.
- Added Scanner diagnostics window with support-oriented ImageCaptureCore device information.
- Added persistent source and duplex settings.
- Updated UI, localization, About information and Universal DMG packaging to 0.3.0 Alpha.

### Validation status

Apple Silicon and Intel compilation, unit tests and Universal DMG packaging are verified through GitHub Actions. Physical scanner behavior still requires an external Mac + scanner test before Beta.

## 0.2.0 Alpha

- Added real scanner discovery through Apple ImageCaptureCore.
- Added a hardware scanning backend alongside Mock Scanner.
- Real scanners are shown in the same device selector as diagnostic virtual scanners.
- Added first real scan request using file-based ImageCaptureCore transfer.
- DPI and color / grayscale / B&W mode are applied to the selected functional unit when supported by the scanner module.
- Hardware scan is staged as PNG and converted locally to JPG, PNG or one-page PDF.
- Restored AMURWEB company logo, AMURWEB Scan product logo and app icon to packaged app.
- Updated Intel + Apple Silicon CI packaging to 0.2.0 Alpha Universal DMG.
