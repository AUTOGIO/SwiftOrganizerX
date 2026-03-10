// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftOrganizerX",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SwiftOrganizerX", targets: ["SwiftOrganizerX"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "SwiftOrganizerX",
            dependencies: [],
            path: "Sources/SwiftOrganizerX"
        ),
        .testTarget(
            name: "SwiftOrganizerXTests",
            dependencies: ["SwiftOrganizerX"],
            path: "Tests/SwiftOrganizerXTests"
        )
    ]
)
