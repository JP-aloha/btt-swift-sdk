// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BTTInstrumentor",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(
            name: "BTTInstrumentor",
            targets: ["BTTInstrumentor"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-syntax.git",
            from: "509.0.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "BTTInstrumentor",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax")
            ]
        )
    ]
)
