# optiCLOUD Sensor

optiCLOUD Sensor turns a phone into a sensor for [optiCLOUD](https://dashboard.opticloud.io), the IoT platform by optiMEAS. The phone sends its own measurements and its position to a device in optiCLOUD and reacts to commands coming back. There are two native apps: Swift with SwiftUI on iOS, Kotlin with Jetpack Compose on Android.

## Status

Early development. Nothing here is ready for use yet, and the apps are not in the stores.

| Part | State |
| --- | --- |
| Specification | Draft for stage 1 in [`docs/spec/`](docs/spec/), parts tested against an optiCLOUD test server |
| Shared test vectors | Draft in [`docs/spec/vectors/`](docs/spec/vectors/) |
| Android app | Passes the shared test vectors. Sign-in and device selection work against an optiCLOUD server. No connection or transmission yet |
| iOS app | Passes the shared test vectors. Sign-in, device selection, the MQTT connection, the offline queue, commands, and transmission of the `device` and `location` groups work against an optiCLOUD server, also in the background. The test area shows commands, shared attributes, and the offline queue, and sends single values; alarms are not in it yet. Other sensors are not built yet. The iOS app leads the implementation of stage 1 |

## Planned features

Stage 1, the foundation:

- Sign-in with a personal optiCLOUD account, choice of tenant, project, and device, or creation of a new device
- Sensor values the phone offers, selected by group or single item, sent at a configurable rate and only when they change
- Position, also in the background when the user allows it
- A persistent buffer, so that no measurement is lost without a network
- A test area for every communication path: telemetry, attributes, commands, alarms
- The data volume of the app over the mobile network and Wi-Fi
- A button that opens optiCLOUD

Later stages: journal entries stored as notes in optiCLOUD, photos, and values measured on the body such as heart rate. The full plan is in the [project brief](docs/project-brief.md#stages).

## Repository layout

```
docs/project-brief.md   product idea, decisions, stages, open questions
docs/spec/              platform-neutral specification, the master for both apps
docs/spec/vectors/      test vectors both apps run in their protocol tests
docs/design/            app icon sources and brand colors, shared by both apps
ios/                    iOS app (Swift, SwiftUI)
android/                Android app (Kotlin, Jetpack Compose)
```

The specification in `docs/spec/` defines the behavior. Neither app is the reference for the other. Each app follows the design standards of its platform.

## Building

### Android

Requirements: Android Studio, current stable release. The app needs Android 12 (API 31) or newer.

```
cd android
./gradlew assembleDebug
./gradlew :core:test
```

The second command runs the tests of the platform-neutral logic, including the shared test vectors, on the JVM without a device. Or open the `android` directory in Android Studio.

### iOS

Requirements: Xcode, current stable release. The app needs iOS 26 or newer.

For a build on a device, copy `ios/Config/Local.xcconfig.example` to `ios/Config/Local.xcconfig` and enter your development team. Then open `ios/OptiCloudSensor.xcodeproj` in Xcode, or build and test from the command line:

```
cd ios
xcodebuild -scheme OptiCloudSensor -destination 'platform=iOS Simulator,name=iPhone 17' test
```

The logic package also runs on its own, without a simulator:

```
cd ios/SensorCore
swift test
```

## Contributing

The apps are developed by optiMEAS. Rules for working in this repository are in [`CLAUDE.md`](CLAUDE.md) and in the platform files [`ios/CLAUDE.md`](ios/CLAUDE.md) and [`android/CLAUDE.md`](android/CLAUDE.md). Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/).

## License

[MIT](LICENSE). Libraries used by the apps keep their own licenses; the apps will show them on a license screen.
