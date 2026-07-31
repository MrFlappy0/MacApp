// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MLXChatApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MLXChatApp", targets: ["MLXChatApp"])
    ],
    dependencies: [
        // Dépendances pour le réseau
        .package(url: "https://github.com/apple/swift-numerics.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        
        // Dépendances pour la gestion des fichiers
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.0"),
        
        // Dépendances pour l'interface utilisateur
        .package(url: "https://github.com/swiftlang/swift-ui.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "MLXChatApp",
            dependencies: [
                .product(name: "Numerics", package: "swift-numerics"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "SwiftUI", package: "swift-ui")
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .unsafeFlags(["-cross-module-optimization", "-O"]),
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        ),
        .testTarget(
            name: "MLXChatAppTests",
            dependencies: ["MLXChatApp"]
        )
    ],
    swiftLanguageModes: [.v5]
)
