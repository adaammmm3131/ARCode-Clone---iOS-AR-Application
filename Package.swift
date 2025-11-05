// swift-tools-version: 5.9
// Package.swift pour ARCode Clone
// Dependencies nécessaires pour le projet

import PackageDescription

let package = Package(
    name: "ARCodeClone",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "ARCodeClone",
            targets: ["ARCodeClone"])
    ],
    dependencies: [
        // Swinject pour dependency injection
        .package(url: "https://github.com/Swinject/Swinject.git", from: "2.8.0"),
        
        // Alamofire pour networking (alternative à URLSession)
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        
        // SwiftLint pour linting (dev dependency)
        .package(url: "https://github.com/realm/SwiftLint.git", from: "0.54.0"),
        
        // Sentry pour error tracking et performance monitoring
        .package(url: "https://github.com/getsentry/sentry-cocoa", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "ARCodeClone",
            dependencies: [
                "Swinject",
                "Alamofire",
                .product(name: "Sentry", package: "sentry-cocoa")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "ARCodeCloneTests",
            dependencies: ["ARCodeClone"],
            path: "Tests",
            linkerSettings: [
                .linkedFramework("XCTest", .when(platforms: [.iOS]))
            ]
        )
    ]
)

