import SwiftUI

struct DiagnosticsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var model: ScanViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(settings.t("diagnostics.title"))
                        .font(.title2.bold())
                    Text(settings.t("diagnostics.body"))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if model.diagnosticsBusy {
                    ProgressView()
                }
            }

            ScrollView {
                Text(model.diagnosticText.isEmpty ? settings.t("diagnostics.loading") : model.diagnosticText)
                    .font(.system(size: 12, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(12)
            }
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            HStack {
                Button(settings.t("diagnostics.refresh")) {
                    Task { await model.refreshDiagnostics() }
                }
                .disabled(model.diagnosticsBusy)

                Button(settings.t("diagnostics.copy")) {
                    model.copyDiagnostics()
                }
                .disabled(model.diagnosticText.isEmpty)

                Spacer()
                Text("AMURWEB Scan 0.6.0 Alpha")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(22)
        .frame(width: 720, height: 560)
        .task {
            await model.refreshDiagnostics()
        }
    }
}
