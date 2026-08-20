# Changelog

## 0.2.0 Alpha

- Added real scanner discovery through Apple ImageCaptureCore.
- Added a hardware scanning backend alongside Mock Scanner.
- Real scanners are shown in the same device selector as diagnostic virtual scanners.
- Added first real scan request using file-based ImageCaptureCore transfer.
- DPI and color / grayscale / B&W mode are applied to the selected functional unit when supported by the scanner module.
- Hardware scan is staged as PNG and converted locally to JPG, PNG or one-page PDF.
- Restored AMURWEB company logo, AMURWEB Scan product logo and app icon to packaged app.
- Updated Intel + Apple Silicon CI packaging to 0.2.0 Alpha Universal DMG.

### Validation status

CI compilation and packaging can be validated without physical hardware. Actual scanner compatibility still requires an external Mac + scanner test before stable release.
