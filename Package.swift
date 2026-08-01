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
        // MLX Framework 2.0 - Framework principal pour l'IA
        .package(url: "https://github.com/ml-explore/mlx.git", from: "2.0.0"),
        
        // Pour la gestion des modèles et calculs numériques
        .package(url: "https://github.com/apple/swift-numerics.git", from: "1.0.0"),
        
        // Pour le parsing des arguments en ligne de commande
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        
        // Pour le réseau et les requêtes HTTP (Hugging Face, etc.)
        .package(url: "https://github.com/vapor/vapor.git", from: "4.85.0"),
        .package(url: "https://github.com/vapor/http.git", from: "4.0.0"),
        
        // Pour la gestion avancée des collections
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
        
        // Pour la gestion des fichiers et chemins
        .package(url: "https://github.com/apple/swift-system.git", from: "1.2.1")
    ],
    targets: [
        .target(
            name: "MLXForAll",
            dependencies: [
                .product(name: "MLX", package: "mlx"),
                .product(name: "Numerics", package: "swift-numerics"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "HTTP", package: "vapor"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "SystemPackage", package: "swift-system")
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                // Optimisations pour la performance
                .enableExperimentalFeature("StrictConcurrency"),
                .unsafeFlags([
                    "-cross-module-optimization",
                    "-O",
                    "-Xfrontend", "-experimental-allow-module-with-multiple-public-targets"
                ]),
                // Fonctionnalités modernes de Swift
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ForwardTrailingClosures"),
                .enableUpcomingFeature("ImplicitOpenExistentials")
            ]
        ),
        .testTarget(
            name: "MLXForAllTests",
            dependencies: ["MLXForAll"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
