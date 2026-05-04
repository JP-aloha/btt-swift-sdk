// swift-tools-version:5.9
import PackageDescription
import CompilerPluginSupport

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
            targets: ["BlueTriangle"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-syntax.git",
            from: "509.0.0"
        )
    ],
    targets: [
        .macro(
            name: "BTTMacrosPlugin",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(
            name: "BTTMacros",
            dependencies: ["BTTMacrosPlugin"]),
        .target(
          name: "BlueTriangle",
          dependencies: ["Backtrace","AppEventLogger", "BTTMacros", "BTTInstrumentor"],
          resources: [
            .copy("PrivacyInfo.xcprivacy"),
            .process("Scripts")
          ]
        ),
        .target(
            name: "Backtrace",
            dependencies: []),
        .target(
            name: "AppEventLogger",
            dependencies: []),
         .binaryTarget(
                name: "BTTInstrumentor",
                path: "Artifacts/BTTInstrumentor.artifactbundle"
            ),
        .testTarget(
            name: "BlueTriangleTests",
            dependencies: ["BlueTriangle"]),
        .testTarget(
            name: "ObjcCompatibilityTests",
            dependencies: ["BlueTriangle"])
    ]
)
