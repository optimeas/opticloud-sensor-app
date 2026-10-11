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
| Predecessor | The earlier "optiCLOUD Demo App" (Expo and React Native) stays in a private company repository. It is not a model for this product: nothing is derived from its code, design, specification, or history. |

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
- **Photos do not travel over MQTT.** The message size is limited. The supported way to upload them is an open question.
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

## Protocol facts

Read from the optiCLOUD source. Each one still needs a test against a running server before `spec/` relies on it.

| Purpose | Direction | Topic |
| --- | --- | --- |
| Telemetry | publish | `v2/json/devices/me/telemetry` |
| Client attributes | publish and subscribe | `v2/json/devices/me/attributes` |
| Shared-attribute request | publish | `v2/json/devices/me/attributes/request/<requestId>` |
| Shared-attribute response | subscribe | `v2/json/devices/me/attributes/response/+` |
| Server RPC request | subscribe | `v2/json/devices/me/rpc/request/+` |
| Server RPC response | publish | `v2/json/devices/me/rpc/response/<requestId>` |
| Alarm update | publish | `v3/json/devices/me/alarms` |

- The connection is MQTT over TLS, by convention on port 8883. The port belongs to the installation, so it is part of the endpoint setting.
- The device access token is the MQTT user name, without a password.
- Payloads are UTF-8 JSON.

## Notes for the build

- Apps built with Xcode 27 must use the UIKit scene life cycle. A SwiftUI app life cycle covers this.
- Keep the repository in a path without spaces.
- No MQTT client library is chosen yet. Evaluate the current options for both platforms, including their licenses and the notices they require in the app.

## Before a store release

- Apple's reviewers need a working test account and device on an optiCLOUD server.
- Permission texts for location (including background), motion sensors, and camera must say plainly why the app needs them.
- The privacy declarations for both stores must list location, photos, and user-written text.
- The app needs a screen with the open-source license notices.

## Answers from the optiCLOUD source

Read from the optiCLOUD source on 2026-10-12. None of this has been tested against a running server yet. Exact endpoints and payloads go into `spec/` once it is confirmed that optiMEAS supports these interfaces for customers.

- **Tenants.** A user account can hold several roles, each bound to one tenant. Sign-in is a two-step exchange: the app sends the user name and password and receives the list of roles with their tenants, then signs in with the chosen role and receives an access token and a refresh token. A signed-in user can list their roles again and switch between them.
- **Sign-in methods.** There are three. Password sign-in is the basic one. Two-factor sign-in can be switched on per tenant and per role; the server then sends a code by e-mail, and the app confirms it in a separate step before it receives the tokens. Single sign-on uses OAuth2 / OpenID Connect providers configured on the server and ends with a one-time code that is exchanged for the tokens.
- **Registering a device.** The user needs the tenant administrator or tenant user role and the permission to create devices. The server generates the access token when it creates the device. Reading the token is a separate request with its own permission. The tenant's license can limit the number of devices; the server then refuses the registration.
- **Projects.** A tenant is divided into projects. A new device is placed in the project the user has currently selected and also in the tenant's root project.
- **Quality of service.** The server grants QoS 1 at most. It acknowledges a QoS 1 message only after it has accepted the message for processing, so an acknowledgment means the data arrived. A retry can produce duplicates.
- **Time stamps.** A telemetry message can carry its own time stamp and can hold several samples. Buffered data can therefore be delivered later with the original time stamps.
- **Dashboard URL.** A dashboard opens in the web application at `/dashboards/<dashboard id>` and needs a signed-in user. No URL addresses a tenant; the tenant comes from the signed-in session.

## Open questions

1. Does optiMEAS support the REST interfaces of the web application for a customer app? Provisioning depends on them.
2. Does the app offer an in-app sign-in form, a browser-based sign-in, or both? Two-factor sign-in and single sign-on both have to work for tenants that require them.
3. Does provisioning ask the user for a project, or does it always use the root project?
4. What does the jump to optiCLOUD open when no default dashboard is set? A tenant has no URL of its own.
5. What is the supported way to upload photos, and does optiCLOUD show them? The source contains a storage interface for devices that follows the S3 protocol and signs requests with the device access token. It is not confirmed as supported for customers.
6. How are journal entries represented? The source has no interface made for them. Candidates are a text value sent as telemetry with its own time stamp, or the notes a user can attach to a device, which need a signed-in user instead of the device token.
7. Does the app buffer telemetry while offline? The server allows it; this is a product decision.
8. Which minimum iOS and Android versions does the app support?
