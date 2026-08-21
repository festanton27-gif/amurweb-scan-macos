# Changelog

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

### Validation status

Apple Silicon and Intel compilation, unit tests and Universal DMG packaging are validated through GitHub Actions. Physical scanner behavior still requires an external Mac + scanner test before Beta.

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
- Updated About, diagnostics footer and Universal DMG packaging to 0.5.0 Alpha.

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
