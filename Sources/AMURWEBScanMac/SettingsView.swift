import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Form {
            Toggle(settings.t("settings.checkUpdates"), isOn: $settings.automaticUpdateChecks)
            Text(settings.t("settings.checkUpdates.note"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(22)
        .frame(width: 460)
    }
}
