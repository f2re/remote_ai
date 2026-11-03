// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RemoteAI",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "RemoteAI", targets: ["RemoteAI"])
    ],
    targets: [
        .executableTarget(
            name: "RemoteAI",
            path: "Sources/RemoteAI",
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        ),
        .testTarget(
            name: "RemoteAITests",
            dependencies: ["RemoteAI"],
            path: "Tests/RemoteAITests",
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        )
    ]
)
