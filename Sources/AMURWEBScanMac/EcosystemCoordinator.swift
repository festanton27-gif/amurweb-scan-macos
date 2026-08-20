import AppKit
import Foundation
import AMURWEBScanCore

struct LocalizedRemoteText: Codable {
    let ru: String
    let en: String

    func value(for language: AppLanguage) -> String {
        language == .ru ? ru : en
    }
}

struct PromotionCatalog: Codable {
    let products: [PromotionProduct]
}

struct PromotionProduct: Codable, Identifiable {
    let id: String
    let title: LocalizedRemoteText
    let description: LocalizedRemoteText
    let url: String
    let enabled: Bool?
}

struct UpdateManifest: Codable {
    let version: String
    let pageURL: String?
    let downloadURL: String?
    let message: LocalizedRemoteText?
    let critical: Bool?
}

struct PromotionPresentation: Identifiable {
    let id: String
    let title: String
    let description: String
    let url: URL
}

struct AppNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let actionTitle: String?
    let actionURL: URL?
}

@MainActor
final class EcosystemCoordinator: ObservableObject {
    static let currentVersion = "0.5.0"

    @Published var promotion: PromotionPresentation?
    @Published var notice: AppNotice?

    private let defaults: UserDefaults
    private var didHandleLaunch = false

    private enum Keys {
        static let launchCount = "ecosystem.launchCount"
        static let promotionCache = "ecosystem.promotionCache"
        static let promotionCacheDate = "ecosystem.promotionCacheDate"
        static let lastUpdateCheck = "ecosystem.lastUpdateCheck"
    }

    private let updateURL = URL(string: "https://api.awc-dv.ru/updates/amurweb-scan/macos.json")!
    private let promotionURL = URL(string: "https://api.awc-dv.ru/promotions/amurweb-products/macos.json")!
    private let fallbackURL = URL(string: "https://awc-dv.ru/")!
    private let cacheLifetime: TimeInterval = 24 * 60 * 60

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func handleLaunch(settings: AppSettings) async {
        guard !didHandleLaunch else { return }
        didHandleLaunch = true

        let launchNumber = defaults.integer(forKey: Keys.launchCount) + 1
        defaults.set(launchNumber, forKey: Keys.launchCount)

        if settings.automaticUpdateChecks && shouldRunAutomaticUpdateCheck {
            await checkForUpdates(settings: settings, manual: false)
        }

        guard EcosystemLaunchPolicy.shouldShowPromotion(on: launchNumber) else { return }

        // Let the main window settle before presenting a non-critical ecosystem card.
        try? await Task.sleep(nanoseconds: 700_000_000)
        promotion = await promotionForLaunch(launchNumber, language: settings.language)
    }

    func checkForUpdates(settings: AppSettings, manual: Bool) async {
        if !manual {
            defaults.set(Date().timeIntervalSince1970, forKey: Keys.lastUpdateCheck)
        }

        do {
            let data = try await fetch(updateURL)
            let manifest = try JSONDecoder().decode(UpdateManifest.self, from: data)

            if VersionComparison.isNewer(manifest.version, than: Self.currentVersion) {
                let message = manifest.message?.value(for: settings.language)
                    ?? settings.t("updates.available.body")
                let actionURL = URL(string: manifest.pageURL ?? manifest.downloadURL ?? "")

                notice = AppNotice(
                    title: String(format: settings.t("updates.available.title"), manifest.version),
                    message: message,
                    actionTitle: settings.t("updates.open"),
                    actionURL: actionURL
                )
            } else if manual {
                notice = AppNotice(
                    title: settings.t("updates.current.title"),
                    message: String(format: settings.t("updates.current.body"), Self.currentVersion),
                    actionTitle: nil,
                    actionURL: nil
                )
            }
        } catch {
            if manual {
                notice = AppNotice(
                    title: settings.t("updates.error.title"),
                    message: settings.t("updates.error.body"),
                    actionTitle: nil,
                    actionURL: nil
                )
            }
        }
    }

    func dismissPromotion() {
        promotion = nil
    }

    private var shouldRunAutomaticUpdateCheck: Bool {
        let last = defaults.double(forKey: Keys.lastUpdateCheck)
        guard last > 0 else { return true }
        return Date().timeIntervalSince1970 - last >= cacheLifetime
    }

    private func promotionForLaunch(_ launchNumber: Int, language: AppLanguage) async -> PromotionPresentation {
        if let freshData = cachedPromotionData(requireFresh: true),
           let promotion = decodePromotion(from: freshData, launchNumber: launchNumber, language: language) {
            return promotion
        }

        do {
            let data = try await fetch(promotionURL)
            if let catalog = try? JSONDecoder().decode(PromotionCatalog.self, from: data),
               !catalog.products.isEmpty {
                defaults.set(data, forKey: Keys.promotionCache)
                defaults.set(Date().timeIntervalSince1970, forKey: Keys.promotionCacheDate)
                if let promotion = makePromotion(from: catalog, launchNumber: launchNumber, language: language) {
                    return promotion
                }
            }
        } catch {
            // Promotions must never interfere with scanning or app startup.
        }

        if let staleData = cachedPromotionData(requireFresh: false),
           let promotion = decodePromotion(from: staleData, launchNumber: launchNumber, language: language) {
            return promotion
        }

        return builtInPromotion(language: language)
    }

    private func cachedPromotionData(requireFresh: Bool) -> Data? {
        guard let data = defaults.data(forKey: Keys.promotionCache) else { return nil }
        guard requireFresh else { return data }

        let cachedAt = defaults.double(forKey: Keys.promotionCacheDate)
        guard cachedAt > 0,
              Date().timeIntervalSince1970 - cachedAt < cacheLifetime else { return nil }
        return data
    }

    private func decodePromotion(from data: Data, launchNumber: Int, language: AppLanguage) -> PromotionPresentation? {
        guard let catalog = try? JSONDecoder().decode(PromotionCatalog.self, from: data) else { return nil }
        return makePromotion(from: catalog, launchNumber: launchNumber, language: language)
    }

    private func makePromotion(from catalog: PromotionCatalog, launchNumber: Int, language: AppLanguage) -> PromotionPresentation? {
        let enabled = catalog.products.filter { $0.enabled != false }
        guard !enabled.isEmpty else { return nil }

        // Deterministic local rotation. No impression/click history is sent anywhere.
        let index = max(0, launchNumber - 11) % enabled.count
        let product = enabled[index]
        guard let url = URL(string: product.url), ["https", "http"].contains(url.scheme?.lowercased() ?? "") else {
            return nil
        }

        return PromotionPresentation(
            id: product.id,
            title: product.title.value(for: language),
            description: product.description.value(for: language),
            url: url
        )
    }

    private func builtInPromotion(language: AppLanguage) -> PromotionPresentation {
        if language == .ru {
            return PromotionPresentation(
                id: "amurweb-ecosystem",
                title: "Другие решения AMURWEB",
                description: "Полезные программы, плагины и сервисы Амурского Веб Центра.",
                url: fallbackURL
            )
        }
        return PromotionPresentation(
            id: "amurweb-ecosystem",
            title: "More AMURWEB products",
            description: "Useful apps, plugins and services from Amur Web Center.",
            url: fallbackURL
        )
    }

    private func fetch(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = 4
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("AMURWEB Scan macOS/\(Self.currentVersion)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
