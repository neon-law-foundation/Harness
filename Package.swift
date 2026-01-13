// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Standards",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/fluent.git", from: "4.13.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.12.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.8.1"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.121.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.8.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.2.0"),
        .package(url: "https://github.com/awslabs/swift-aws-lambda-runtime.git", from: "2.5.1"),
        .package(url: "https://github.com/awslabs/swift-openapi-lambda.git", from: "2.1.0"),
        .package(url: "https://github.com/apple/swift-openapi-generator.git", from: "1.10.3"),
        .package(url: "https://github.com/apple/swift-openapi-runtime.git", from: "1.9.0"),
        .package(url: "https://github.com/swift-server/swift-openapi-vapor.git", from: "1.0.1"),
        .package(url: "https://github.com/apple/swift-configuration.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "StandardsRules",
            dependencies: []
        ),
        .target(
            name: "StandardsDAL",
            dependencies: [
                "StandardsRules",
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Yams", package: "Yams"),
            ],
            exclude: [
                "README.md"
            ],
            resources: [
                .copy("Examples"),
                .copy("Seeds"),
            ]
        ),
        .executableTarget(
            name: "StandardsCLI",
            dependencies: [
                "StandardsRules",
                .target(name: "StandardsDAL", condition: .when(platforms: [.macOS])),
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .executableTarget(
            name: "MigrationRunner",
            dependencies: [
                "StandardsDAL",
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .executableTarget(
            name: "StandardsAPI",
            dependencies: [
                "StandardsDAL",
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "OpenAPILambda", package: "swift-openapi-lambda"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Configuration", package: "swift-configuration"),
            ],
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ],
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
            ]
        ),
        .executableTarget(
            name: "StandardsAPIServer",
            dependencies: [
                "StandardsDAL",
                .product(name: "Vapor", package: "vapor"),
                .product(name: "OpenAPIVapor", package: "swift-openapi-vapor"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Configuration", package: "swift-configuration"),
            ],
            resources: [
                .copy("Public")
            ],
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ],
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
            ]
        ),
        .testTarget(
            name: "StandardsDALTests",
            dependencies: [
                "StandardsDAL",
                "StandardsRules",
            ]
        ),
        .testTarget(
            name: "StandardsCLITests",
            dependencies: [
                "StandardsCLI"
            ]
        ),
    ]
)
