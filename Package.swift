// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "RightNow",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "RightNowCore", targets: ["RightNowCore"]),
        .executable(name: "RightNow", targets: ["RightNow"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/sindresorhus/KeyboardShortcuts",
            exact: "1.15.0"
        )
    ],
    targets: [
        .target(name: "RightNowCore"),
        .executableTarget(
            name: "RightNow",
            dependencies: [
                "RightNowCore",
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts")
            ]
        ),
        .testTarget(
            name: "RightNowCoreTests",
            dependencies: ["RightNowCore"]
        )
    ]
)
