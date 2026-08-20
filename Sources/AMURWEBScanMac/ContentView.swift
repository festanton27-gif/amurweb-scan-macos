import AppKit
import SwiftUI
import AMURWEBScanCore

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var model: ScanViewModel

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 350)
            Divider()
            preview
        }
        .frame(minWidth: 1040, minHeight: 700)
        .background(Color(nsColor: .windowBackgroundColor))
        .task {
            await model.refresh(settings: settings)
        }
        .alert(settings.t("error"), isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK") { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var sidebar: some View {
        VStack(spacing: 16) {
            header
            statusBadges

            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    fieldLabel(settings.t("scanner"))
                    Picker("", selection: Binding(
                        get: { model.selectedDeviceID ?? "" },
                        set: {
                            model.selectedDeviceID = $0
                            settings.lastScannerID = $0
                            model.statusKey = model.selectedDevice?.isMock == true ? "status.mock" : "status.hardware"
                        }
                    )) {
                        ForEach(model.devices) { device in
                            Text(device.name).tag(device.id)
                        }
                    }
                    .labelsHidden()

                    fieldLabel(settings.t("resolution"))
                    Picker("", selection: $settings.selectedDPI) {
                        ForEach([150, 200, 300, 600], id: \.self) { dpi in
                            Text("\(dpi) DPI").tag(dpi)
                        }
                    }
                    .labelsHidden()

                    fieldLabel(settings.t("mode"))
                    Picker("", selection: $settings.colorMode) {
                        Text(settings.t("color")).tag(ScanColorMode.color)
                        Text(settings.t("grayscale")).tag(ScanColorMode.grayscale)
                        Text(settings.t("bw")).tag(ScanColorMode.blackAndWhite)
                    }
                    .labelsHidden()

                    fieldLabel(settings.t("format"))
                    Picker("", selection: $settings.format) {
                        Text("JPG").tag(ScanFormat.jpg)
                        Text("PNG").tag(ScanFormat.png)
                        Text("PDF").tag(ScanFormat.pdf)
                    }
                    .labelsHidden()
                }
                .padding(4)
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    fieldLabel(settings.t("folder"))
                    Text(settings.outputFolder?.path ?? "—")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .textSelection(.enabled)

                    Button {
                        model.chooseFolder(settings: settings)
                    } label: {
                        Label(settings.t("choose.folder"), systemImage: "folder.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.orange)

                    Button {
                        model.openOutputFolder(settings: settings)
                    } label: {
                        Label(settings.t("open.folder"), systemImage: "folder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Divider()
                    Text(settings.t("next.file"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(model.nextFileName(settings: settings))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .lineLimit(2)
                }
                .padding(4)
            }

            Button {
                Task { await model.scan(settings: settings) }
            } label: {
                HStack {
                    if model.isBusy { ProgressView().controlSize(.small) }
                    Image(systemName: "scanner")
                    Text(settings.t("scan"))
                        .font(.system(size: 17, weight: .bold))
                }
                .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.orange)
            .disabled(model.isBusy || model.selectedDevice == nil)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Circle()
                    .fill(model.isBusy ? Color.orange : Color.green)
                    .frame(width: 8, height: 8)
                Text(settings.t(model.statusKey))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(18)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.7))
    }

    private var header: some View {
        HStack(spacing: 12) {
            Group {
                if let image = bundledImage(named: "ProductLogo") {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "scanner.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.orange)
                        .padding(8)
                }
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 3) {
                Text("AMURWEB Scan")
                    .font(.system(size: 24, weight: .bold))
                Text(settings.t("app.subtitle"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
        }
    }

    private var statusBadges: some View {
        HStack(spacing: 6) {
            badge(settings.t("badge.free"), color: .green)
            badge(settings.t("badge.offline"), color: .blue)
            badge(settings.t("badge.mac"), color: .gray)
            if model.selectedDevice?.isMock == true {
                badge(settings.t("badge.mock"), color: .orange)
            } else {
                badge(settings.t("badge.hardware"), color: .orange)
            }
            Spacer()
        }
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(color.opacity(0.14))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(settings.t("preview"))
                        .font(.system(size: 20, weight: .semibold))
                    Text(settings.t("alpha.notice"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(settings.t("refresh")) {
                    Task { await model.refresh(settings: settings) }
                }
                .disabled(model.isBusy)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(nsColor: .textBackgroundColor))
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 3)

                if let url = model.previewURL,
                   let image = NSImage(contentsOf: url) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(28)
                } else {
                    VStack(spacing: 14) {
                        Image(systemName: "doc.viewfinder")
                            .font(.system(size: 62, weight: .light))
                            .foregroundStyle(.orange)
                        Text(settings.t("preview.empty.title"))
                            .font(.title3.weight(.semibold))
                        Text(settings.t("preview.empty.body"))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 520)
                    }
                    .padding(40)
                }
            }
        }
        .padding(22)
    }
}
