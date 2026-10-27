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
        // Apache 2.0. Version 3 is chosen in docs/project-brief.md. Our fork: 3.0.0-rc.1 with the fix for a crash
        // when packets arrive after the connection closed (upstream issue #274, pull request #280). Back to the
        // original once a release has the fix.
        .package(url: "https://github.com/optimeas/mqtt-nio.git", revision: "faa68d6ff52e19fff03df7992243b18c526ce4ed"),
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
