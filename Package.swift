// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Focus",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Focus",
            path: "Sources"
        )
    ]
)
