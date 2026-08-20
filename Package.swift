// swift-tools-version: 5.10
import PackageDescription

var products: [Product] = [
    .library(name: "AMURWEBScanCore", targets: ["AMURWEBScanCore"])
]

var targets: [Target] = [
    .target(
        name: "AMURWEBScanCore",
        path: "Sources/AMURWEBScanCore"
    ),
    .testTarget(
        name: "AMURWEBScanCoreTests",
        dependencies: ["AMURWEBScanCore"],
        path: "Tests/AMURWEBScanCoreTests"
    )
]

#if os(macOS)
products.append(.executable(name: "AMURWEBScanMac", targets: ["AMURWEBScanMac"]))
targets.append(
    .executableTarget(
        name: "AMURWEBScanMac",
        dependencies: ["AMURWEBScanCore"],
        path: "Sources/AMURWEBScanMac"
    )
)
#endif

let package = Package(
    name: "AMURWEBScanMac",
    platforms: [
        .macOS(.v13)
    ],
    products: products,
    targets: targets
)
