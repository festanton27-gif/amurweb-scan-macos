import AMURWEBScanCore

enum ReleaseNotice {
    static func text(language: AppLanguage) -> String {
        let detail: String
        switch language {
        case .ru:
            detail = "релиз-кандидат перед Stable · требуется финальная проверка на реальном Mac и сканере"
        case .en:
            detail = "release candidate before Stable · final real Mac and scanner validation required"
        }
        return "\(AppMetadata.displayVersion) · \(detail)"
    }
}
