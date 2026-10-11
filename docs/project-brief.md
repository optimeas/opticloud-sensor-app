# Project brief: optiCLOUD Sensor

This is the starting point for the project. It records the product idea, the decisions made so far, the rules for working in this repository, and the open questions. Nothing described here is implemented yet.

Read this first. When a decision changes, change this document in the same commit.

## Product idea

optiCLOUD Sensor turns a phone into a sensor for optiCLOUD, the IoT platform by optiMEAS. The phone sends its own measurements and user input to an optiCLOUD device and reacts to commands coming back.

The app is a real tool, not a demonstration. It must feel like a native app on each platform.

Spelling is exact: **optiMEAS**, **optiCLOUD**, **optiCLOUD Sensor**.

## Decisions

| Topic | Decision |
| --- | --- |
| Technology | Native apps: Swift with SwiftUI on iOS, Kotlin with Jetpack Compose on Android. No cross-platform framework. |
| Design | Each app follows its platform's design standards (Apple Human Interface Guidelines, Material Design) and uses the system font. The optiMEAS brand shows in colors and logo only. |
| Background | The app must keep transmitting in the background when the user has agreed to it. |
| Source | Open source in this public repository under the MIT license. |
| Order | iOS is developed first. Android follows each release. |
| Master | The platform-neutral specification in `spec/` is the master, not either app. Both apps are peers that implement it. |
| optiCLOUD API | The optiCLOUD source code is the reference for MQTT and REST behavior. See [Working with the optiCLOUD source](#working-with-the-opticloud-source). |
| Windows | A Windows desktop app is an idea for later (.NET rather than C++). It is not part of this plan. A PC has few sensors, so it would be a different product. |
| Predecessor | The earlier "optiCLOUD Demo App" (Expo and React Native) stays in a private company repository. Its history is not imported here. |

## Functional areas

### Data the phone sends

- **Sensor values.** Whatever the device offers. The set differs from device to device, so the app discovers at run time what is available.
- **Location.** Geographic position, sent with the other data.
- **Journal entries.** Text messages written by the user, with a time stamp.
- **Photos.** Taken in the app, sent with a time stamp and, where available, the position.

### Connection and transmission

These are two separate states with separate controls:

- **Connected** means the MQTT session is up. The test area works, and RPC commands and shared attributes arrive.
- **Transmitting** means the configured sensor values are being sent at the configured rate. It needs a connection but is started and stopped on its own.

### Test area

A place to check every communication path by hand:

- write a single telemetry value
- write a single client attribute
- raise and clear a manual alarm
- watch a shared attribute change
- receive an RPC command and see the response

It doubles as the diagnostic tool for support.

### Configuration

Settings that stay fixed until the user changes them:

- which of the available sensor values are sent
- the send rate
- the endpoint (server address)
- the device access token (for now; see provisioning)
- an optional default dashboard

### Device provisioning

The goal is that a new user needs no manual token handling:

1. The app proposes a device name, by default the phone's name. The user can change it.
2. The user signs in to optiCLOUD with their user account through the REST API.
3. The user picks a tenant they have access to.
4. If the user has the rights, the app registers the device in that tenant.
5. The app reads the generated access token and stores it in the settings.

After that the user only has to connect and start transmitting.

### Jump to optiCLOUD

A button opens the default dashboard from the settings. If none is set, it opens the device's tenant in optiCLOUD.

## Architecture requirements

- **Background operation shapes the design from the first commit.** Sensor collection and MQTT run in a service layer that does not depend on the user interface, with its own reconnect logic.
  - iOS has no general "keep running" mode. The workable route is the location background mode with "Always" permission. Without that permission the app transmits only while it is open. App Review checks this mode closely, so location must be a visible feature with a clear permission text.
  - Android needs a foreground service with a persistent notification. Allowed service types and time limits have tightened in recent Android versions. Check them against the current target SDK.
- **Store and forward.** Journal entries and photos must not be lost without a network. They need a persistent queue that keeps the original time stamp. Whether telemetry is buffered as well is an open question.
- **Photos do not travel over MQTT.** Brokers limit message size. The predecessor uploaded photos over HTTPS to an optiCLOUD storage API. Confirm the current, supported way in the optiCLOUD source.
- **Secrets.** The access token is stored in the Keychain (iOS) and the Keystore-backed storage (Android). The user's password is never stored. Session tokens from the REST login are kept only as long as provisioning needs them.
- **Shared test vectors.** `spec/` contains example payloads and expected results as JSON. Both apps run their protocol tests against the same files.

## Repository layout

```
spec/      platform-neutral specification and test vectors (the master)
ios/       Swift app
android/   Kotlin app
docs/      this brief, setup guides, decisions
```

## Stages

1. **Foundation.** Service layer with background operation, configuration, connect and transmit as separate states, sensor selection and send rate, location, test area, jump to optiCLOUD.
2. **Device provisioning** through the REST API.
3. **Journal entries** with the offline queue.
4. **Photos.**

Each stage is finished on iOS first and then brought to Android.

## Working with the optiCLOUD source

The assistant working in this repository can read the private optiCLOUD source code to find out how communication works. This repository is public. Everything pushed here is visible to everyone, including its history.

- Never copy optiCLOUD source code, comments, or configuration into this repository.
- Never commit internal host names, credentials, tokens, keys, ticket references, or details of internal defects.
- Describe interfaces in your own words in `spec/`: topics, endpoints, payloads, and behavior a client needs.
- Use only interfaces optiMEAS supports for customers. Once the app is public it documents the API in practice. If the source shows an internal or unstable endpoint, ask before using it.
- Signing keys, provisioning profiles, and local environment files stay out of the repository.

## What the predecessor provides

The private repository `opticloud-mobile-demo-app` contains a working client. Use it as a reference; take ideas and facts from it, not its history.

- **Specification** (`docs/specification.md`): connection rules, states, MQTT protocol, alarm model. The new `spec/` should start from it.
- **Native MQTT code** in Swift (CocoaMQTT) and Kotlin (Eclipse Paho): a starting point for the service layer. It was written as an Expo module, so the wrapper has to go.
- **Protocol tests and simulation datasets**: a source for the shared test vectors.
- **Brand colors** (`src/theme/tokens.ts`).
- **Photo upload notes** (`docs/image-upload.md`).

Protocol facts from the predecessor, to be verified against the optiCLOUD source:

| Purpose | Direction | Topic |
| --- | --- | --- |
| Telemetry | publish | `v2/json/devices/me/telemetry` |
| Client attributes | publish and subscribe | `v2/json/devices/me/attributes` |
| Shared-attribute request | publish | `v2/json/devices/me/attributes/request/<requestId>` |
| Shared-attribute response | subscribe | `v2/json/devices/me/attributes/response/+` |
| Server RPC request | subscribe | `v2/json/devices/me/rpc/request/+` |
| Server RPC response | publish | `v2/json/devices/me/rpc/response/<requestId>` |
| Alarm update | publish | `v3/json/devices/me/alarms` |

- The connection is MQTT over TLS on port 8883. The device access token is the MQTT user name, without a password.
- Payloads are UTF-8 JSON.

The predecessor deliberately did things this product must do differently: it ran in the foreground only, used QoS 0, and had no offline queue.

Lessons from its iOS build:

- Apps built with Xcode 27 must use the UIKit scene life cycle. A SwiftUI app life cycle covers this.
- Keep the repository in a path without spaces.
- CocoaMQTT is licensed under EPL 1.0 / EDL 1.0 and Eclipse Paho under EPL / EDL. Both need a license notice in the app. CocoaMQTT's socket library is declared public domain, which some jurisdictions do not recognize.
- The Paho Android client used there (1.2.5) is old. Evaluate the current MQTT client options for both platforms before adopting the predecessor's choice.
- The predecessor's custom font had no license file. This project uses system fonts instead.

## Before a store release

- Apple's reviewers need a working test account and device on an optiCLOUD server.
- Permission texts for location (including background), motion sensors, and camera must say plainly why the app needs them.
- The privacy declarations for both stores must list location, photos, and user-written text.
- The app needs a screen with the open-source license notices.

## Open questions

1. Can one optiCLOUD user belong to several tenants, and how does the REST API list them?
2. Which sign-in methods does the REST API offer (password only, two-factor, single sign-on)? This decides between an in-app form and a browser-based sign-in.
3. Which rights does a user need to register a device, and how does the app read the generated token?
4. What is the supported way to upload photos, and where does optiCLOUD store and show them?
5. How are journal entries represented in optiCLOUD (telemetry, attribute, or something else)?
6. Is telemetry buffered while offline, and with which MQTT quality of service?
7. What does the URL of a dashboard and of a tenant look like for the jump to optiCLOUD?
8. Which minimum iOS and Android versions does the app support?
