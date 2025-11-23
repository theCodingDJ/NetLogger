// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NetLogger",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "NetLogger",
            targets: ["NetLogger"]
        ),
    ],
    targets: [
        .target(
            name: "NetLogger",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "NetLoggerTests",
            dependencies: ["NetLogger"]
        ),
    ]
)
