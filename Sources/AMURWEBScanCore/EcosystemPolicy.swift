import Foundation

public enum EcosystemLaunchPolicy {
    /// First 10 launches are promotion-free. After that the repeating cycle is
    /// 5 launches with an AMURWEB ecosystem promotion, followed by 2 without.
    public static func shouldShowPromotion(on launchNumber: Int) -> Bool {
        guard launchNumber > 10 else { return false }
        let cyclePosition = (launchNumber - 11) % 7
        return cyclePosition < 5
    }
}

public enum VersionComparison {
    /// Compares numeric version components and ignores non-numeric suffixes.
    /// Examples: 1.2.0 > 1.1.9, 0.5.0 Alpha == 0.5.0.
    public static func isNewer(_ candidate: String, than current: String) -> Bool {
        let lhs = components(candidate)
        let rhs = components(current)
        let count = max(lhs.count, rhs.count)

        for index in 0..<count {
            let left = index < lhs.count ? lhs[index] : 0
            let right = index < rhs.count ? rhs[index] : 0
            if left != right { return left > right }
        }
        return false
    }

    private static func components(_ version: String) -> [Int] {
        version
            .split(separator: ".")
            .map { component in
                let digits = component.prefix { $0.isNumber }
                return Int(digits) ?? 0
            }
    }
}
