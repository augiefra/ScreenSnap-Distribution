// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScreenSnapApp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ScreenSnapApp",
            targets: ["ScreenSnapApp"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ScreenSnapApp",
            dependencies: [],
            path: "ScreenSnapApp",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
