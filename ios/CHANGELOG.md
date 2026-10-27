# Changelog of optiCLOUD Sensor for iOS

Every version of the iOS app, newest first, in the format of [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). The app shows the same changes in its version history (`OptiCloudSensor/WhatsNew/ReleaseNotes.swift`), and the user manual on the page [What's New](../docs/manual/en/whats-new.md). A change to one goes into all three. The behavior of the screens is in [docs/spec/whats-new.md](../docs/spec/whats-new.md).

## 0.9.0 – 2026-10-28

### Added

- Live Activity on the Lock Screen and in the Dynamic Island while the app sends: the state, the device, the time since sending started, and the waiting values, with a button to stop.
- Control "Send to optiCLOUD" for Control Center, the Lock Screen, and the Action button.

## 0.8.0 – 2026-10-27

### Added

- Tab Favorites: the default dashboard, the favorites from the web application, and favorites of your own, opened signed in.
- Quick note from the live view. The title is optional; without one, the note takes the first line of the text.
- App Shortcuts for Siri and the Shortcuts app: "New optiCLOUD Note" saves a dictated note without opening the app; "New optiCLOUD Note in the App" opens the form.
- A queue for notes: they wait without a network or sign-in and are sent later. The Diagnosis tab shows them.
- Welcome screen, the screen "What's New" after an update, and the version history.

### Fixed

- The app no longer stops when the connection drops while data arrives (MQTTNIO issue #274; fork `optimeas/mqtt-nio` until a release has the fix).
- The tenant stays shown after choosing a device.
- The list of devices shows only the devices of the chosen project.

## 0.1.0 (build 74) – 2026-10-26

### Added

- Test signal (group `test`) to check in optiCLOUD that every value has arrived.

### Changed

- Sending in the background goes on with the screen locked, with fresh positions (standard location updates instead of live updates).
- The diagnosis log is kept in a file and survives a restart of the app.

### Fixed

- The log no longer shows the installation identifier of the phone.

## 0.1.0 (build 66) – 2026-10-26

The first build on TestFlight.

### Added

- Sign-in to optiCLOUD, choice of tenant, project, and device, and binding of the device to the phone.
- Sensor groups motion, environment, location, activity, device, and sound.
- Sending over MQTT in the foreground and background, with an offline queue.
- Commands and managed settings through shared attributes, and the data volume of the app.
- Diagnosis with log, offline queue, and test values; the app in five languages; the user manual.
