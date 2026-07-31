// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "MLXForAll",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MLXForAll", targets: ["MLXForAll"])
    ],
    dependencies: [
        // MLX Framework 2026 - Dernière version
        .package(url: "https://github.com/ml-explore/mlx.git", from: "2.0.0"),
        .package(url: "https://github.com/ml-explore/mlx-examples.git", from: "2.0.0"),
        
        // Pour la gestion des modèles
        .package(url: "https://github.com/apple/swift-numerics.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        
        // Pour le réseau et Hugging Face
        .package(url: "https://github.com/vapor/vapor.git", from: "4.85.0"),
        .package(url: "https://github.com/vapor/http.git", from: "4.0.0"),
        
        // Pour la gestion des fichiers
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
        
        // Pour l'interface utilisateur
        .package(url: "https://github.com/swiftlang/swift-ui.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "MLXForAll",
            dependencies: [
                .product(name: "MLX", package: "mlx"),
                .product(name: "MLXExamples", package: "mlx-examples"),
                .product(name: "Numerics", package: "swift-numerics"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "HTTP", package: "vapor"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "SwiftUI", package: "swift-ui")
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .unsafeFlags([
                    "-cross-module-optimization",
                    "-O",
                    "-Xfrontend", "-experimental-allow-module-with-multiple-public-targets"
                ]),
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ForwardTrailingClosures"),
                .enableUpcomingFeature("ImplicitOpenExistentials")
            ]
        ),
        .testTarget(
            name: "MLXForAllTests",
            dependencies: ["MLXForAll"]
        )
    ],
    swiftLanguageModes: [.v5]
)
