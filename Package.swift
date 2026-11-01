// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RemoteAI",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "RemoteAI", targets: ["RemoteAI"])
    ],
    targets: [
        .executableTarget(
            name: "RemoteAI",
            path: "Sources/RemoteAI"
        ),
        .testTarget(
            name: "RemoteAITests",
            dependencies: ["RemoteAI"],
            path: "Tests/RemoteAITests"
        )
    ]
)
