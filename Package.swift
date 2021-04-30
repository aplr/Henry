// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Henry",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "Henry",
            targets: ["Henry"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/aplr/Pillarbox",
            from: "1.0.1"
        )
    ],
    targets: [
        .target(
            name: "Henry",
            dependencies: [
                .product(name: "Pillarbox", package: "Pillarbox")
            ]
        ),
        .testTarget(
            name: "HenryTests",
            dependencies: ["Henry"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
