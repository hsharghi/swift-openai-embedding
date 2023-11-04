// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "vector",
    platforms: [
        .macOS(.v13),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.14.0"),
        .package(url: "https://github.com/MacPaw/OpenAI.git", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(name: "vector",
                          dependencies: [
                            .product(name: "PostgresNIO", package: "postgres-nio"),
                            .product(name: "OpenAI", package: "OpenAI"),
                          ],
                          swiftSettings: [
                            .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
                          ]),
    ]
)
