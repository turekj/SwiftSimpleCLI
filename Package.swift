// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftSimpleCLI",
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", .exact("0.40200.0")),
        .package(url: "https://github.com/Carthage/Commandant.git", .exact("0.15.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SwiftSimpleCLI",
            dependencies: ["Commandant", "SwiftSyntax"]),
        .testTarget(
            name: "SwiftSimpleCLITests",
            dependencies: ["SwiftSimpleCLI"]),
    ]
)
