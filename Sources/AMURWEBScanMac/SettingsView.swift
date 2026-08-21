import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var model: ScanViewModel

    var body: some View {
        Form {
            Section {
                Toggle(settings.t("settings.checkUpdates"), isOn: $settings.automaticUpdateChecks)
                Text(settings.t("settings.checkUpdates.note"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Section {
                Toggle(settings.t("settings.showTestScanners"), isOn: $settings.showTestScanners)
                    .onChange(of: settings.showTestScanners) { _ in
                        Task { await model.refresh(settings: settings) }
                    }
                Text(settings.t("settings.showTestScanners.note"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(22)
        .frame(width: 500)
    }
}
