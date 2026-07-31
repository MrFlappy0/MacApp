// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MLXMacApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MLXMacApp", targets: ["MLXMacApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-numerics.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
    ],
    targets: [
        .target(
            name: "MLXMacApp",
            dependencies: [
                .product(name: "Numerics", package: "swift-numerics"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .unsafeFlags(["-cross-module-optimization", "-O"])
            ]
        ),
        .testTarget(
            name: "MLXMacAppTests",
            dependencies: ["MLXMacApp"]
        )
    ],
    swiftLanguageModes: [.v5]
)
