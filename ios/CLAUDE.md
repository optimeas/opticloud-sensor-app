# optiCLOUD Sensor for iOS

This directory holds the iOS app. The rules in the repository root `CLAUDE.md` and the [project brief](../docs/project-brief.md) apply here. The behavior of the app is defined in [`docs/spec/`](../docs/spec/), not in this directory and not in the Android app.

The iOS app leads (see the [project brief](../docs/project-brief.md#decisions)). It settles open questions of the specification and the test vectors in the same pull request as its code.

## Toolchain

- Swift 6 with strict concurrency checking, SwiftUI. No other UI toolkit, no cross-platform framework.
- Xcode, current stable release. The SwiftUI app life cycle (Xcode 27 requires the UIKit scene life cycle, which SwiftUI covers).
- Deployment target: **iOS 26** since 2026-10-25, because the test device runs it. Build with the newest SDK; use APIs that are new in iOS 27 only behind an availability check. The test device is an iPhone 16 Pro Max with iOS 26.7.1. A change of the deployment target is recorded in the project brief.
- Dependencies through Swift Package Manager only. No CocoaPods, no Carthage. Only permissive licenses (MIT, BSD, Apache 2.0); check the license of every transitive dependency before adding a package.
- Bundle identifier: `ch.optimeas.opticloudsensor` (proposal, to be confirmed with the Apple Developer account of optiMEAS before the first release). The development team, signing settings, and provisioning profiles stay out of the repository; use a local, ignored configuration file for them.

## Project layout

- The Xcode project is `ios/OptiCloudSensor.xcodeproj` with the app target `OptiCloudSensor`. Its sources live in `ios/OptiCloudSensor/`, a folder synchronized with the project: add files there, not to the project file. Keep the app target thin: views, app life cycle, permissions, and platform glue.
- The platform-neutral logic (payload encoding, rounding, sending on change, aggregation, the offline queue, the protocol of sign-in and messages) lives in the local Swift package `ios/SensorCore`, so that its tests run with `swift test` and without a simulator. The package has two libraries: `SensorCore` without network code beyond REST, and `DeviceLink`, the MQTT connection on top of MQTTNIO. Commit both `Package.resolved` files. The shared scheme `OptiCloudSensor` runs these tests too.
- The development team is set in `ios/Config/Local.xcconfig`, which Git ignores. `Local.xcconfig.example` shows the format.
- Tests use Swift Testing. Protocol tests load the shared test vectors from `../docs/spec/vectors/` and run every case. A failing vector is a defect in the app, not in the vector.
- TestFlight builds are made with `Tools/upload-testflight.sh` from a clean checkout of `main`. It archives the Release configuration and uploads it with `Config/ExportOptions.plist`. The version is `MARKETING_VERSION` in the project; the build number is the number of commits on `HEAD`, set at archive time, so it rises with every merge. The app declares `ITSAppUsesNonExemptEncryption = NO`: it uses only the encryption of the system and of TLS.
- The Debug configuration has the bundle identifier `ch.optimeas.opticloudsensor.dev` and the name "optiCLOUD Sensor Dev", so that a development build and the TestFlight build live side by side on one iPhone. They have separate settings, Keychain, and offline queue, and each binds its own device in optiCLOUD.
- Sensors, background location, and MQTT over the mobile network need a real iPhone. The simulator is enough for the user interface and the package tests.

## Architecture

- The service layer (sensor sampling, buffering, MQTT) does not depend on the user interface and has its own reconnect logic.
- Background operation uses the location background mode with "Always" permission. Without that permission the app transmits only while it is open. Location is therefore a visible feature of the app with a clear permission text, not a hidden means to stay alive.
- While transmitting with a location item selected, `LocationSampler` runs `CLLocationUpdate.liveUpdates()`, started in the foreground. It asks for "When in use" first and for "Always" once after that; later changes are up to the user in Settings. Tested with "Always" on the test device: sampling and sending go on with the app in the background and the screen locked, and the location arrow goes off when sending stops.
- Do not use `CLBackgroundActivitySession`. With "Always" it is not needed, and on iOS 26 the system did not release the first session of a process: after it was invalidated and released, it stayed active, kept the blue indicator in the Dynamic Island, and was restored after the app ended, which started the app again in the background. Only a restart of the phone removed it. To stop the updates, leave the `liveUpdates()` loop.
- Keep three layers apart: sensor sources, the buffer / offline queue, and the sender. Later stages add a second sender. Do not let the MQTT client reach into sensor code or the other way round.
- Secrets go into the Keychain: the device access token, the refresh token, and the installation identifier. Never into UserDefaults, never into logs. The password is never stored.
- Every permission the app asks for has a usage text in the Info.plist that says plainly why the app needs it. The app has a privacy manifest (`PrivacyInfo.xcprivacy`) that lists the data it collects and the required-reason APIs it uses.

## Design

- Follow the Apple Human Interface Guidelines. Use the system font, standard SwiftUI controls, and SF Symbols. Support Dynamic Type, dark mode, and VoiceOver.
- The optiMEAS brand shows in the accent color and the logo only. Do not copy the look of the Android app.
- Every text the user sees is in the string catalogs `Localizable.xcstrings` and `InfoPlist.xcstrings` (permission texts), with English as the source and German, French, Italian, and Spanish translations (see the [project brief](../docs/project-brief.md#decisions), Languages). A pull request that adds or changes a text brings all four translations. Write texts as string literals in SwiftUI views or with `String(localized:)`, so that the compiler extracts them; Xcode adds them to the catalog when it builds. Without the Xcode editor: a clean build, then `xcrun xcstringstool sync` with the `.stringsdata` files from the build folder.

## MQTT client

Use **MQTTNIO** 3.x (`swift-server-community/mqtt-nio`, Apache 2.0). Do not add another MQTT library. A change of the library is decided for both platforms together and recorded in the project brief. The app shows the license texts of MQTTNIO and its dependencies.

## Working in this repository

- Work on branches named `ios/<topic>`. Merge into `main` through a pull request.
- Change only files under `ios/` and, when the specification needs it, under `docs/`. Never touch `android/`.
- The user manual in [`docs/manual/`](../docs/manual/) describes the iOS app. A change the user can see goes into the German and English pages in the same pull request, and into the French, Italian, and Spanish pages as described in [`docs/manual/TRANSLATING.md`](../docs/manual/TRANSLATING.md).
- When the specification is unclear or wrong, stop and say so. Do not resolve it in the code. The fix goes into `docs/spec/` first, then into both apps.
- Never read the predecessor app "optiCLOUD Demo App" for this work; nothing is derived from it.
- Keep the repository path free of spaces.
