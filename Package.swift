// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ProtectYourEyes",
    platforms: [
        .macOS(.v12)
    ],
    targets: [
        .executableTarget(
            name: "ProtectYourEyes",
            path: "Sources/ProtectYourEyes"
        )
    ]
)
