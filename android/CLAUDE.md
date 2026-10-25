# optiCLOUD Sensor for Android

This directory holds the Android app. The rules in the repository root `CLAUDE.md` and the [project brief](../docs/project-brief.md) apply here. The behavior of the app is defined in [`docs/spec/`](../docs/spec/), not in this directory and not in the iOS app.

## Toolchain

- Kotlin with Jetpack Compose. No other UI toolkit, no cross-platform framework.
- Android Studio, current stable release. Gradle with the Kotlin DSL and a version catalog (`gradle/libs.versions.toml`).
- `compileSdk` and `targetSdk` follow the newest stable Android release.
- `minSdk` is **31** (Android 12). From Android 12 on, the current rules for foreground services and permissions apply, so the app needs no special cases for older versions. The test device is a Samsung Galaxy A17 5G with Android 16. A change of `minSdk` is recorded in the project brief.
- Application id: `com.optimeas.opticloudsensor` (proposal, to be confirmed before the first release).
- Dependencies that ship with the app need a permissive license (MIT, BSD, Apache 2.0); check every transitive dependency. Test and build tools such as JUnit are exempt.

## Project layout

- `android/` is the Gradle root; run Gradle there.
- `:app` is the Android app: activities, Compose screens, services, permissions, and platform glue. Keep it thin.
- `:core` is plain Kotlin on the JVM, without Android: payload encoding, rounding, sending on change, aggregation, sensor selection, queue batching, journal notes, and the REST client for sign-in and device selection (`core.api`). Later the MQTT messages.
- Secrets (session tokens, device token, installation identifier) are kept by `storage/SecretStore`: AES-GCM with a key in the Android Keystore, only the encrypted value in the app's preferences. Its tests run with `./gradlew :core:test` and without a device or emulator.
- Tests use JUnit 5 through `kotlin.test`.

## Architecture

- The service layer (sensor sampling, buffering, MQTT) does not depend on the user interface and has its own reconnect logic. It runs in a foreground service with a persistent notification. Check the allowed foreground service types and time limits against the current `targetSdk`.
- Keep three layers apart: sensor sources, the buffer / offline queue, and the sender. Later stages add a second sender. Do not let the MQTT client reach into sensor code or the other way round.
- Secrets go into Keystore-backed storage. Never into SharedPreferences in plain text, never into logs.
- Protocol tests load the shared test vectors from `../docs/spec/vectors/` and run every case. A failing vector is a defect in the app, not in the vector.

## MQTT client

Use the **HiveMQ MQTT Client** 1.4.x (`com.hivemq:hivemq-mqtt-client`, Apache 2.0). Do not add another MQTT library; Eclipse Paho is no longer maintained. A change of the library is decided for both platforms together and recorded in the project brief. The app shows the license texts of the client and its dependencies.

## Working in this repository

- Work on branches named `android/<topic>`. Merge into `main` through a pull request.
- Change only files under `android/` and, when the specification needs it, under `docs/`. Never touch `ios/`.
- When the specification is unclear or wrong, stop and say so. Do not resolve it in the code. The fix goes into `docs/spec/` first, then into both apps.
- Keep the repository path free of spaces.
