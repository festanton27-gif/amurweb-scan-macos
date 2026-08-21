import AMURWEBScanCore

enum ReleaseNotice {
    static func text(language: AppLanguage) -> String {
        let detail: String
        switch language {
        case .ru:
            detail = "диагностический session trace текущего запуска · требуется реальный Mac и сканер"
        case .en:
            detail = "current-run diagnostic session trace · real Mac and scanner still required"
        }
        return "\(AppMetadata.displayVersion) · \(detail)"
    }
}
