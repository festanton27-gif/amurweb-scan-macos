import AppKit
import SwiftUI

struct SupportView: View {
    @EnvironmentObject private var settings: AppSettings
    private let programURL = URL(string: "https://awc-dv.ru/it-uslugi-i-vozmozhnosti/razrabotka-po/gotovoe-po/programma-dlya-skanera/")!
    private let emailURL = URL(string: "mailto:info@awc-dv.ru")!

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(settings.t("support.title"))
                .font(.title2.bold())
            Text(settings.t("support.body"))
                .fixedSize(horizontal: false, vertical: true)
            Divider()
            HStack {
                Button("info@awc-dv.ru") { NSWorkspace.shared.open(emailURL) }
                Button(settings.t("program.page")) { NSWorkspace.shared.open(programURL) }
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .padding(26)
        .frame(width: 560, height: 300)
    }
}
