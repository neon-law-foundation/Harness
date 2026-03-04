// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// MigrationRunner depends on fluent-postgres-driver, which pulls in postgres-nio → swift-nio-ssl
// (CNIOBoringSSL). CNIOBoringSSL fails to compile against Windows SDK 10.0.26100.0 due to
// winsock.h/winsock2.h redefinition conflicts. Exclude it on Windows until the upstream issue
// is resolved: https://github.com/apple/swift-nio-ssl/issues/342
#if os(Windows)
let windowsExcludedTargets: [Target] = []
#else
let windowsExcludedTargets: [Target] = [
    .executableTarget(
        name: "MigrationRunner",
        dependencies: [
            "HarnessDAL",
            .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
            .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
            .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
            .product(name: "NIOPosix", package: "swift-nio"),
            .product(name: "Logging", package: "swift-log"),
        ]
    )
]
#endif

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
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.12.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.8.1"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.8.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.62.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.2.0"),
        .package(url: "https://github.com/awslabs/swift-aws-lambda-runtime.git", from: "2.5.1"),
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
    ] + windowsExcludedTargets
)
