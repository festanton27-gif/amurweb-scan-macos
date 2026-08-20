import SwiftUI

struct LegalView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(settings.t("legal.title"))
                .font(.title2.bold())
            ScrollView {
                Text(settings.t("legal.body"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            Text("© 2026 Амурский Веб Центр (АМУРВЕБ) · awc-dv.ru · info@awc-dv.ru")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(26)
        .frame(width: 620, height: 380)
    }
}
