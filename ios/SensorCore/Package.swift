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
        .library(name: "DeviceLink", targets: ["DeviceLink"]),
    ],
    dependencies: [
        // Apache 2.0. Version 3 is chosen in docs/project-brief.md; pinned until it has a final release.
        .package(url: "https://github.com/swift-server-community/mqtt-nio.git", exact: "3.0.0-rc.1"),
        // Apache 2.0. Lets MQTTNIO use the Network framework, which iOS requires.
        .package(url: "https://github.com/apple/swift-nio-transport-services.git", from: "1.26.0"),
        // Apache 2.0. Only to switch off the log of MQTTNIO.
        .package(url: "https://github.com/apple/swift-log.git", from: "1.14.0"),
    ],
    targets: [
        // Platform-neutral logic without network code: payloads, rounding, selection, the offline queue, REST.
        .target(name: "SensorCore"),
        // The MQTT connection of the device (see docs/spec/connection.md).
        .target(
            name: "DeviceLink",
            dependencies: [
                "SensorCore",
                .product(name: "MQTTNIO", package: "mqtt-nio"),
                .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .testTarget(name: "SensorCoreTests", dependencies: ["SensorCore"]),
    ]
)
