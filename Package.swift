// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "blue-triangle",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "BlueTriangle",
            targets: ["BlueTriangle"]),
        .library(
                name: "BlueTriangleWithClarity",
                targets: ["BlueTriangleWithClarity"])
    ],
    dependencies: [
            .package(url: "https://github.com/microsoft/clarity-apps.git", from: "3.0.0")
        ],
    targets: [
        
        .target(
            name: "BlueTriangle",
            dependencies: ["Backtrace", "AppEventLogger"],
            path: "Sources/BlueTriangle" //
        ),
        .target(
            name: "BlueTriangleWithClarity",
            dependencies: [
                "Backtrace",
                "AppEventLogger",
                .product(name: "Clarity", package: "clarity-apps")
            ],
            path: "Sources/BlueTriangleWithClarity",
            swiftSettings: [.define("WITH_CLARITY")]
        ),
        .target(
            name: "Backtrace",
            dependencies: []),
        .target(
            name: "AppEventLogger",
            dependencies: []),
        .testTarget(
            name: "BlueTriangleTests",
            dependencies: ["BlueTriangle"]),
        .testTarget(
            name: "ObjcCompatibilityTests",
            dependencies: ["BlueTriangle"])
    ]
)
