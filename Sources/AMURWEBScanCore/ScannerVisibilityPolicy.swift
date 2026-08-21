import Foundation

public enum ScannerVisibilityPolicy {
    public static func visibleDevices(
        from devices: [ScannerDevice],
        includeTestDevices: Bool
    ) -> [ScannerDevice] {
        guard !includeTestDevices else { return devices }
        return devices.filter { !$0.isMock }
    }
}
