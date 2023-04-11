// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "simprokconnection",
    platforms: [
        .macOS(.v10_14)
    ],
    products: [
        .library(
            name: "simprokconnection",
            targets: ["simprokconnection"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/simprok-dev/simproktools-ios.git",
            exact: .init(1, 2, 44)
        ),
    ],
    targets: [
        .target(
            name: "simprokconnection",
            dependencies: [
                .product(
                    name: "simproktools",
                    package: "simproktools-ios"
                )
            ]
        )
    ]
)
