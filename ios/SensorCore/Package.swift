// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SensorCore",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(name: "SensorCore", targets: ["SensorCore"]),
    ],
    targets: [
        .target(name: "SensorCore"),
        .testTarget(name: "SensorCoreTests", dependencies: ["SensorCore"]),
    ]
)
