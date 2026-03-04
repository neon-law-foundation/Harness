// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Harness",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "HarnessDAL", targets: ["HarnessDAL"]),
        .library(name: "HarnessRules", targets: ["HarnessRules"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/fluent-kit.git", from: "1.52.2"),
        .package(url: "https://github.com/vapor/sql-kit.git", from: "3.33.2"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.8.1"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.8.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.62.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.2.0"),
    ],
    targets: [
        .target(
            name: "HarnessRules",
            dependencies: [
                .product(name: "Yams", package: "Yams")
            ]
        ),
        .target(
            name: "HarnessDAL",
            dependencies: [
                "HarnessRules",
                .product(name: "FluentKit", package: "fluent-kit"),
                .product(name: "FluentSQL", package: "fluent-kit"),
                .product(name: "SQLKit", package: "sql-kit"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Yams", package: "Yams"),
            ],
            exclude: [
                "README.md",
                "ERD-1.svg",
                "ERD-1.png",
                "ERD.md",
                "export-erd.sh",
            ],
            resources: [
                .copy("Examples"),
                .copy("Seeds"),
            ]
        ),
        .executableTarget(
            name: "HarnessCLI",
            dependencies: [
                "HarnessRules",
                "HarnessDAL",
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "SQLKit", package: "sql-kit"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .testTarget(
            name: "HarnessDALTests",
            dependencies: [
                "HarnessDAL",
                "HarnessRules",
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "NIOPosix", package: "swift-nio"),
            ]
        ),
        .testTarget(
            name: "HarnessCLITests",
            dependencies: [
                "HarnessCLI",
                "HarnessRules",
                "HarnessDAL",
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "SQLKit", package: "sql-kit"),
                .product(name: "NIOPosix", package: "swift-nio"),
            ]
        ),
    ]
)
