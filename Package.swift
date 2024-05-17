// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "WalletCore",
    platforms: [
        .macOS(.v12), .iOS(.v14)
    ],
    products: [
        .library(name: "WalletCore", type: .dynamic, targets: ["WalletCore"]),
        .library(name: "WalletCoreCore", targets: ["WalletCoreCore"]),
        .library(name: "WalletCoreKeeper", targets: ["WalletCoreKeeper"])
    ],
    dependencies: [
        .package(url: "https://github.com/tonkeeper/ton-swift", exact: "1.0.6"),
        .package(url: "https://github.com/tonkeeper/ton-api-swift", from: "0.1.1"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", .upToNextMinor(from: "0.3.0"))
    ],
    targets: [
        .target(name: "WalletCore",
                dependencies: [
                    .target(name: "WalletCoreCore"),
                    .target(name: "WalletCoreKeeper")
                ]),
        .target(name: "WalletCoreCore",
                dependencies: [.product(name: "TonSwift", package: "ton-swift")],
                path: "Sources/WalletCoreCore"),
        .testTarget(name: "WalletCoreCoreTests",
                    dependencies: ["WalletCoreCore"],
                    path: "Tests/WalletCoreCoreTests"),
        .target(name: "WalletCoreKeeper",
                dependencies: [
                    .target(name: "WalletCoreCore"),
                    .target(name: "TonConnectAPI"),
                    .product(name: "TonSwift", package: "ton-swift"),
                    .product(name: "TonAPI", package: "ton-api-swift"),
                    .product(name: "TonStreamingAPI", package: "ton-api-swift"),
                    .product(name: "StreamURLSessionTransport", package: "ton-api-swift"),
                    .product(name: "EventSource", package: "ton-api-swift"),
                ],
                path: "Sources/WalletCoreKeeper",
                resources: [.copy("PackageResources")]),
        .testTarget(name: "WalletCoreKeeperTests",
                    dependencies: ["WalletCoreKeeper"],
                    path: "Tests/WalletCoreKeeperTests",
                    resources: [.copy("PackageResources")]),
        .target(name: "TonConnectAPI",
                dependencies: [
                    .product(
                        name: "OpenAPIRuntime",
                        package: "swift-openapi-runtime"
                    ),
                ],
                path: "Packages/TonConnectAPI",
                sources: ["Sources"]
               )
    ]
)
