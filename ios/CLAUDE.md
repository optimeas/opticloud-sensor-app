# optiCLOUD Sensor for iOS

This directory holds the iOS app. The rules in the repository root `CLAUDE.md` and the [project brief](../docs/project-brief.md) apply here. The behavior of the app is defined in [`docs/spec/`](../docs/spec/), not in this directory and not in the Android app.

## Toolchain

- Swift with SwiftUI. No other UI toolkit, no cross-platform framework.
- Xcode, current stable release. The SwiftUI app life cycle (Xcode 27 requires the UIKit scene life cycle, which SwiftUI covers).
- Deployment target: **iOS 26** (proposal: one major version behind the newest release, to be confirmed before the first release).
- Dependencies through Swift Package Manager only. No CocoaPods, no Carthage.
- Bundle identifier: to be set from the Apple Developer account of optiMEAS Switzerland GmbH before the first device build. Signing settings and provisioning profiles stay out of the repository.

## Architecture

- The service layer (sensor sampling, buffering, MQTT) does not depend on the user interface and has its own reconnect logic.
- Background operation uses the location background mode with "Always" permission. Without that permission the app transmits only while it is open. Location is therefore a visible feature of the app with a clear permission text, not a hidden means to stay alive.
- Keep three layers apart: sensor sources, the buffer / offline queue, and the sender. Later stages add a second sender. Do not let the MQTT client reach into sensor code or the other way round.
- Secrets go into the Keychain. Never into UserDefaults, never into logs.
- Protocol tests load the shared test vectors from `../docs/spec/vectors/` and run every case. A failing vector is a defect in the app, not in the vector.

## MQTT client

Use **MQTTNIO** 3.x (`swift-server-community/mqtt-nio`, Apache 2.0). Do not add another MQTT library. A change of the library is decided for both platforms together and recorded in the project brief. The app shows the license texts of MQTTNIO and its dependencies.

## Working in this repository

- Work on branches named `ios/<topic>`. Merge into `main` through a pull request.
- Change only files under `ios/` and, when the specification needs it, under `docs/`. Never touch `android/`.
- When the specification is unclear or wrong, stop and say so. Do not resolve it in the code. The fix goes into `docs/spec/` first, then into both apps.
- Keep the repository path free of spaces.
