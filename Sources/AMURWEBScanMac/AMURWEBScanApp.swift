import SwiftUI
import AMURWEBScanCore

@main
struct AMURWEBScanApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var model = ScanViewModel()

    var body: some Scene {
        WindowGroup("AMURWEB Scan") {
            ContentView()
                .environmentObject(settings)
                .environmentObject(model)
        }
        .defaultSize(width: 1180, height: 760)
        .commands {
            AppCommands(settings: settings, model: model)
        }

        Window("About AMURWEB Scan", id: "about") {
            AboutView().environmentObject(settings)
        }
        .windowResizability(.contentSize)

        Window("Support", id: "support") {
            SupportView().environmentObject(settings)
        }
        .windowResizability(.contentSize)

        Window("Scanner diagnostics", id: "diagnostics") {
            DiagnosticsView()
                .environmentObject(settings)
                .environmentObject(model)
        }
        .windowResizability(.contentSize)

        Window("Legal information", id: "legal") {
            LegalView().environmentObject(settings)
        }
        .windowResizability(.contentSize)
    }
}

struct AppCommands: Commands {
    @ObservedObject var settings: AppSettings
    @ObservedObject var model: ScanViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button(settings.t("menu.about")) { openWindow(id: "about") }
        }

        CommandMenu(settings.t("menu.scan")) {
            Button(settings.t("menu.scan.now")) {
                Task { await model.scan(settings: settings) }
            }
            .keyboardShortcut("s", modifiers: [.command])
            .disabled(model.isBusy || model.selectedDevice == nil)

            Button(settings.t("menu.cancel")) {
                model.cancelScan()
            }
            .keyboardShortcut(".", modifiers: [.command])
            .disabled(!model.isBusy || model.isCancelling)

            Divider()

            Button(settings.t("menu.refresh")) {
                Task { await model.refresh(settings: settings) }
            }
            .keyboardShortcut("r", modifiers: [.command])
            .disabled(model.isBusy)
        }

        CommandMenu(settings.t("menu.language")) {
            Button("Русский") { settings.language = .ru }
            Button("English") { settings.language = .en }
        }

        CommandMenu(settings.t("menu.help")) {
            Button(settings.t("menu.support")) { openWindow(id: "support") }
            Button(settings.t("menu.diagnostics")) { openWindow(id: "diagnostics") }
            Divider()
            Button(settings.t("menu.legal")) { openWindow(id: "legal") }
        }
    }
}
