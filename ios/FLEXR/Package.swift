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
        // Add dependencies here if needed
        // Example: .package(url: "https://github.com/realm/realm-swift.git", from: "10.40.0")
    ],
    targets: [
        .target(
            name: "FLEXR",
            dependencies: [],
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
