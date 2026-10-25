# optiCLOUD Sensor

optiCLOUD Sensor turns a phone into a sensor for [optiCLOUD](https://dashboard.opticloud.io), the IoT platform by optiMEAS. The phone sends its own measurements and its position to a device in optiCLOUD and reacts to commands coming back. There are two native apps: Swift with SwiftUI on iOS, Kotlin with Jetpack Compose on Android.

## Status

Early development. Nothing here is ready for use yet, and the apps are not in the stores.

| Part | State |
| --- | --- |
| Specification | Draft for stage 1 in [`docs/spec/`](docs/spec/), parts tested against an optiCLOUD test server |
| User manual | Draft in [`docs/manual/`](docs/manual/) in German, English, French, Italian, and Spanish, for the iOS app |
| Shared test vectors | Draft in [`docs/spec/vectors/`](docs/spec/vectors/) |
| Android app | Passes the shared test vectors. Sign-in and device selection work against an optiCLOUD server. No connection or transmission yet |
| iOS app | Passes the shared test vectors. Sign-in, device selection, the MQTT connection, the offline queue, commands, and transmission of the sensor groups `device`, `location`, `motion`, `environment`, `activity`, and `sound` work against an optiCLOUD server, also in the background (the sound level only while the app is open). The sensors are selected on the phone or in optiCLOUD. The app counts its own data volume. It is in German, English, French, Italian, and Spanish. It has three tabs: Live with the switch for sending and the current values, Diagnosis, and Settings with the open source licenses. Diagnosis, the test area, shows commands, shared attributes, and the offline queue, sends single values, and exports its log as text to pass on; alarms are not in it yet. The iOS app leads the implementation of stage 1 |

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
docs/manual/            user manual in five languages, published in the optiMEAS documentation
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

The code is under the [MIT](LICENSE) license, the user manual in `docs/manual/` under [CC BY 4.0](docs/manual/LICENSE). Libraries used by the apps keep their own licenses; the iOS app shows them, and its own license, under Settings › About.
