import AppKit
import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var ecosystem: EcosystemCoordinator

    var body: some View {
        ContentView()
            .task {
                await ecosystem.handleLaunch(settings: settings)
            }
            .sheet(item: $ecosystem.promotion) { promotion in
                PromotionView(promotion: promotion)
                    .environmentObject(settings)
            }
            .alert(item: $ecosystem.notice) { notice in
                if let actionTitle = notice.actionTitle, let actionURL = notice.actionURL {
                    return Alert(
                        title: Text(notice.title),
                        message: Text(notice.message),
                        primaryButton: .default(Text(actionTitle)) {
                            NSWorkspace.shared.open(actionURL)
                        },
                        secondaryButton: .cancel(Text(settings.t("later")))
                    )
                }

                return Alert(
                    title: Text(notice.title),
                    message: Text(notice.message),
                    dismissButton: .default(Text("OK"))
                )
            }
    }
}
