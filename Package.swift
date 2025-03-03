// swift-tools-version:5.9.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

extension Target {
    static func target(
        name: String,
        sources: [String],
        dependencies: [Target.Dependency] = []
    ) -> Target {
        .target(
            name: name,
            dependencies: dependencies,
            path: "Sources",
            exclude: Array(Set(["Data", "UI", "Testing"]).subtracting(sources)),
            sources: sources,
            publicHeadersPath: nil,
            cSettings: nil,
            cxxSettings: nil,
            swiftSettings: nil,
            linkerSettings: nil
        )
    }
}

extension Target {
    static func testTarget(
        name: String,
        sources: [String],
        dependencies: [Target.Dependency] = []
    ) -> Target {
        .testTarget(
            name: name,
            dependencies: dependencies,
            path: "Tests",
            exclude: Array(Set(["Data"]).subtracting(sources)),
            sources: sources,
            resources: nil,
            cSettings: nil,
            cxxSettings: nil,
            swiftSettings: nil,
            linkerSettings: nil
        )
    }
}

let package = Package(
    name: "AppsPlus",
    platforms: [
        .iOS(.v15), .tvOS(.v15), .macOS(.v10_15), .watchOS(.v6)
    ],
    products: [
        .library(
            name: "AppsPlusData",
            targets: ["AppsPlusData"]
        ),
        .library(
            name: "AppsPlusUI",
            targets: ["AppsPlusUI"]
        ),
        .library(
            name: "AppsPlusTesting",
            targets: ["AppsPlusTesting"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/typelift/SwiftCheck", exact: "0.12.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", exact: "1.2.3"),
        .package(url: "https://github.com/Image-Plus-Apps/combine-extensions", exact: "0.0.6"),
        .package(url: "https://github.com/pusher/pusher-websocket-swift.git", exact: "8.0.0"),
        .package(url: "https://github.com/groue/GRDB.swift", exact: "7.3.0")
    ],
    targets: [
        .target(
            name: "AppsPlusData",
            sources: ["Data"],
            dependencies: [
                .product(name: "PusherSwift", package: "pusher-websocket-swift"),
                .product(name: "GRDB", package: "GRDB.swift")
            ]
        ),
        .testTarget(
            name: "AppsPlusDataTests",
            sources: ["Data"],
            dependencies: [
                "AppsPlusData",
                "SwiftCheck"
            ]
        ),
        .target(
            name: "AppsPlusUI",
            sources: ["UI"],
            dependencies: [.product(name: "CombineExtensions", package: "combine-extensions")]
        ),
        .target(
            name: "AppsPlusTesting",
            sources: ["Testing"],
            dependencies: ["AppsPlusData", "SwiftCheck"]
        )
    ]
)
