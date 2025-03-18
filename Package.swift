// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AsyncReactiveSequences",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AsyncReactiveSequences",
            targets: ["AsyncReactiveSequences"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.3"),
        .package(url: "https://github.com/groue/Semaphore.git", from: "0.1.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AsyncReactiveSequences",
            dependencies: [
                .product(name: "OrderedCollections", package: "swift-collections"),
                .product(name: "Semaphore", package: "Semaphore")
            ]
        ),
        .testTarget(
            name: "AsyncReactiveSequencesTests",
            dependencies: [
                "AsyncReactiveSequences",
            ]
        ),
    ]
)
