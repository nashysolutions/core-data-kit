// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "core-data-kit",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_13),
        .watchOS(.v5),
        .tvOS(.v12),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "CoreDataKit",
            targets: ["CoreDataKit"]
        ),
    ],
    targets: [
        .target(
            name: "CoreDataKit"),
        .testTarget(
            name: "CoreDataKitTests",
            dependencies: ["CoreDataKit"]
        ),
    ]
)
