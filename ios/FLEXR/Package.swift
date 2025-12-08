// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FLEXR",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "FLEXR",
            targets: ["FLEXR"]
        ),
    ],
    dependencies: [
        // Core Data is native - no external dependencies needed
    ],
    targets: [
        .target(
            name: "FLEXR",
            dependencies: [
                // Core Data is a framework, not a package dependency
            ],
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "FLEXRTests",
            dependencies: ["FLEXR"],
            path: "Tests"
        ),
    ]
)
