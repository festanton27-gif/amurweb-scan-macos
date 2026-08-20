import AppKit
import SwiftUI

struct AboutView: View {
    @EnvironmentObject private var settings: AppSettings

    private let programURL = URL(string: "https://awc-dv.ru/it-uslugi-i-vozmozhnosti/razrabotka-po/gotovoe-po/programma-dlya-skanera/")!
    private let siteURL = URL(string: "https://awc-dv.ru/")!
    private let emailURL = URL(string: "mailto:info@awc-dv.ru")!

    var body: some View {
        VStack(spacing: 16) {
            Group {
                if let image = bundledImage(named: "CompanyLogo") {
                    Image(nsImage: image).resizable().scaledToFit()
                } else {
                    Text("AMURWEB").font(.largeTitle.bold())
                }
            }
            .frame(height: 120)

            Text("AMURWEB Scan")
                .font(.title.bold())
            Text("0.6.0 Alpha · macOS")
                .foregroundStyle(.secondary)

            Text(settings.t("about.description"))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 500)

            Divider()
            Text(settings.t("about.developer"))
                .fontWeight(.semibold)

            HStack(spacing: 18) {
                Button("awc-dv.ru") { NSWorkspace.shared.open(siteURL) }
                    .buttonStyle(.link)
                Button("info@awc-dv.ru") { NSWorkspace.shared.open(emailURL) }
                    .buttonStyle(.link)
            }

            HStack {
                Text(settings.t("program.page"))
                Button(settings.t("go")) { NSWorkspace.shared.open(programURL) }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
            }
        }
        .padding(28)
        .frame(width: 580, height: 500)
    }
}
