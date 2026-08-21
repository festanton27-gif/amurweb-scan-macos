# Changelog

## 0.9.0 Alpha

- Added a release-verification gate for the final packaged macOS artifact.
- Packaging now derives the application version from `AppMetadata` instead of keeping a second hardcoded package version.
- Visible Alpha version text now follows `AppMetadata` automatically, preventing stale UI version labels.
- Apple Silicon CI explicitly verifies an `arm64` executable and Intel CI verifies `x86_64`.
- Universal packaging explicitly verifies that the final executable contains both `arm64` and `x86_64` architectures.
- Added `scripts/verify-release.sh` to validate `Info.plist`, bundle version, build number, bundle identifier and minimum macOS version.
- Release verification checks the packaged app with `codesign --verify --deep --strict`.
- Release verification validates the DMG SHA-256 against `SHA256SUMS.txt`.
- CI mounts the completed DMG and verifies that it contains the application, an `Applications` symlink and the expected Universal executable.
- Updated the external tester guide with safe first-launch guidance for the current ad-hoc signed Alpha build.
- Scanner acquisition, flatbed/ADF multipage scanning, duplex, cancellation, support reports, update checks and AMURWEB promotions remain unchanged.

### Validation status

This version is intended to make CI/package validation substantially closer to the checks required for a distributable build. Physical scanner behavior still requires an external Mac + scanner test before Beta. Stable public distribution additionally requires Developer ID signing and Apple notarization.

## 0.8.0 Alpha

- Added a single privacy-conscious support report for external testing and technical support.
- The report includes AMURWEB Scan version, macOS version, CPU architecture, active scan settings and scanner capabilities.
- The report excludes scanned-document contents, scan file names, document/output-folder paths and persistent scanner identifiers.
- Added a reusable Core privacy filter that replaces backend `ID:` values with `ID: redacted`.
- Added unit tests verifying scanner-ID redaction while preserving useful diagnostic data.
- Updated Scanner diagnostics UI to generate, refresh, copy and save the combined support report.
- Universal build artifact now contains the DMG, SHA-256 checksum and a versioned Russian external-tester guide.
- Scanner acquisition, flatbed/ADF multipage scanning, duplex, cancellation, update checks and AMURWEB promotions remain unchanged.
- Updated RU/EN copy and centralized app version to 0.8.0 Alpha.

### Validation status

Apple Silicon and Intel compilation, Core tests and Universal DMG/tester-package creation are validated through GitHub Actions. Physical scanner behavior still requires an external Mac + scanner test before Beta.

## 0.7.0 Alpha

- Mock Flatbed and Mock ADF are hidden by default so normal users see only real scanners.
- Added **Show test scanners** setting for explicit hardware-independent testing.
- Added a dedicated no-scanner UI state with refresh guidance and quick test-scanner opt-in.
- Added unit tests verifying that Mock devices are hidden normally and restored when test mode is enabled.
- Added **Show result in Finder** for the most recent scan output.
- Scanner diagnostics can now be saved directly as a UTF-8 `.txt` report in addition to being copied.
- Centralized Swift-side version/channel/platform metadata in `AppMetadata` to avoid inconsistent version labels.
- Update-check User-Agent and current-version comparison now use the centralized app metadata.
- Scanner acquisition, manual flatbed multipage PDF, automatic ADF multipage, duplex and cancellation remain unchanged.
- Updated RU/EN interface text and Universal DMG packaging to 0.7.0 Alpha.

## 0.6.0 Alpha

- Added manual multi-page PDF scanning for ordinary flatbed scanners without an ADF.
- The workflow scans one page at a time and asks whether to scan the next page, finish the document, or cancel.
- When source is Automatic and the scanner reports a Flatbed unit, manual multi-page mode explicitly selects Flatbed to avoid an accidental ADF path.
- Intermediate pages are scanned as PNG into a temporary session directory and removed after completion/cancellation.
- Only the final combined PDF is saved to the selected document folder and consumes the normal file-number sequence.
- Manual multi-page mode is available only for PDF and is disabled when ADF is selected.
- Existing automatic ADF multipage PDF, duplex, JPG/PNG multipage output, cancellation, diagnostics and scanner acquisition paths remain unchanged.
- Retained 0.5.0 update notifications and AMURWEB ecosystem promotion behavior.
- Updated RU/EN UI, About information and Universal DMG packaging to 0.6.0 Alpha.

## 0.5.0 Alpha

- Added lightweight update notifications through the AMURWEB update endpoint.
- Automatic update checks run at most once per 24 hours and can be disabled in Settings.
- Added manual **Check for updates** command under Help.
- Added AMURWEB ecosystem product promotions without third-party ad networks.
- Promotion policy is local: launches 1–10 have no promotion, then the app repeats 5 launches with promotion / 2 without.
- Added unit tests for the promotion cycle and numeric version comparison.
- Promotion catalog is cached locally for 24 hours; stale cache or a built-in AMURWEB card is used if the server is unavailable.
- Launch count, impressions and clicks are not sent to the server.
- Replaced the misleading OFFLINE badge with LOCAL FILES because version/product metadata may now be fetched separately.
- Updated privacy/legal copy to make clear that scanned documents remain local.
- Scanner discovery, ImageCaptureCore acquisition, ADF, duplex, multi-page PDF, cancellation and diagnostics behavior remain unchanged from 0.4.0.

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

## 0.3.0 Alpha

- Added scan source selection: Automatic, Flatbed and Document Feeder (ADF).
- Added ADF duplex option; it is enabled only when the selected feeder reports duplex support.
- Added multi-page hardware scan handling for ImageCaptureCore feeder jobs.
- PDF output can now combine all pages returned by one ADF scan into a single multi-page PDF.
- JPG/PNG multi-page scans are saved as separate sequentially numbered image files.
- Upgraded Mock ADF to generate multi-page simplex and duplex jobs for hardware-independent testing.
- Added Scanner diagnostics window with support-oriented ImageCaptureCore device information.
- Added persistent source and duplex settings.

## 0.2.0 Alpha

- Added real scanner discovery through Apple ImageCaptureCore.
- Added a hardware scanning backend alongside Mock Scanner.
- Real scanners are shown in the same device selector as diagnostic virtual scanners.
- Added first real scan request using file-based ImageCaptureCore transfer.
- DPI and color / grayscale / B&W mode are applied to the selected functional unit when supported by the scanner module.
- Hardware scan is staged as PNG and converted locally to JPG, PNG or one-page PDF.
- Restored AMURWEB company logo, AMURWEB Scan product logo and app icon to packaged app.
