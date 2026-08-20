import AppKit
import SwiftUI

struct PromotionView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    let promotion: PromotionPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                if let logo = bundledImage(named: "CompanyLogo") {
                    Image(nsImage: logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 58, height: 58)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(settings.t("promotion.header"))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(promotion.title)
                        .font(.title2.bold())
                }
            }

            Text(promotion.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            Text(settings.t("promotion.privacy"))
                .font(.caption)
                .foregroundStyle(.tertiary)

            HStack {
                Spacer()
                Button(settings.t("close")) {
                    dismiss()
                }
                Button(settings.t("promotion.more")) {
                    NSWorkspace.shared.open(promotion.url)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
        .padding(24)
        .frame(width: 500)
    }
}
