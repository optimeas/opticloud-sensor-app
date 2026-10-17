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
| Order | One app leads, the other follows. The leading app implements a stage first; the following app catches up from `docs/spec/`. The lead can change between the apps; a change is recorded here. **The iOS app leads since 2026-10-17.** Each app is developed in its own working session and on its own branches. |
| Lead | The leading app settles open questions in `docs/spec/` and the shared test vectors, in the same pull request as its code. The following app implements from the specification, not by translating the other app's code, and solves platform questions such as background operation and design on its own. Behavior the following app finds missing or wrong in the specification goes into `docs/spec/` first, whichever app leads. |
| Master | The platform-neutral specification in `docs/spec/` is the master, not either app. Both apps are peers that implement it. |
| optiCLOUD API | The optiCLOUD source code is the reference for MQTT and REST behavior. See [Working with the optiCLOUD source](#working-with-the-opticloud-source). |
| Windows | A Windows desktop app is an idea for later (.NET rather than C++). It is not part of this plan. A PC has few sensors, so it would be a different product. |
| REST interfaces | optiMEAS supports the REST interfaces of the optiCLOUD web application for this app. |
| Sign-in | The user signs in to optiCLOUD in a form inside the app, not in a browser. Single sign-on is a separate topic and not part of the stages below. |
| Platform versions | As new as possible. Both apps target the newest iOS and Android versions. The minimum versions are set in `ios/CLAUDE.md` and `android/CLAUDE.md`. On Android the minimum is provisionally API 26 (Android 8.0), because the only test device at the moment is a Samsung Galaxy S7; it is raised when a current phone replaces it. |
| Remote control | optiCLOUD may control the phone: the app accepts every RPC command, reacts to changes of shared attributes, and lets optiCLOUD set settings through them. |
| Sensors | The app offers every sensor the phone has, up to values measured on the body such as heart rate and body temperature. |
| Predecessor | The earlier "optiCLOUD Demo App" (Expo and React Native) stays in a private company repository. It is not a model for this product: nothing is derived from its code, design, specification, or history. |

## Functional areas

### Data the phone sends

- **Sensor values.** Whatever the device offers. The set differs from device to device, so the app discovers at run time what is available. This includes values measured on the body, such as heart rate and body temperature, which reach the phone from a watch or another device.
- **Location.** Geographic position, sent with the other data.
- **Journal entries.** Text messages written by the user, with a time stamp. optiCLOUD stores them as notes on the device. The time stamp of a note is the moment the user saved the entry in the app, also when it is delivered later. There are two kinds: general entries, which need no user, and personal entries, for example from a train driver, which belong to a signed-in user.
- **Photos.** Taken in the app, sent with a time stamp and, where available, the position. The app uploads them through the device storage interface; optiCLOUD stores them, and a dashboard widget shows the latest photo of a series.

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
2. The user signs in to optiCLOUD with their user account in a form inside the app. If the tenant requires two-factor sign-in, the user also enters the code sent by e-mail.
3. The user picks a tenant they have access to.
4. If the user has the rights, the app registers the device in the root project of that tenant. The app does not ask for a project.
5. The app reads the generated access token and stores it in the settings.

After that the user only has to connect and start transmitting.

### Jump to optiCLOUD

A button opens the default dashboard from the settings. If none is set, it opens the home view of optiCLOUD.

## Architecture requirements

- **Background operation shapes the design from the first commit.** Sensor collection and MQTT run in a service layer that does not depend on the user interface, with its own reconnect logic.
  - iOS has no general "keep running" mode. The workable route is the location background mode with "Always" permission. Without that permission the app transmits only while it is open. App Review checks this mode closely, so location must be a visible feature with a clear permission text.
  - Android needs a foreground service with a persistent notification. Allowed service types and time limits have tightened in recent Android versions. Check them against the current target SDK.
- **Store and forward.** Journal entries and photos must not be lost without a network. They need a persistent queue that keeps the original time stamp. Telemetry is buffered as well while the phone is offline and is sent later with QoS 1 and its original time stamps.
- **Photos do not travel over MQTT.** The message size is limited. The app uploads them through the device storage interface, which follows the S3 protocol and signs requests with the device access token.
- **Secrets.** The access token is stored in the Keychain (iOS) and the Keystore-backed storage (Android). The user's password is never stored. Session tokens from the REST login are kept only as long as provisioning needs them.
- **Shared test vectors.** `docs/spec/` contains example payloads and expected results as JSON. Both apps run their protocol tests against the same files.

## Repository layout

```
docs/        this brief, setup guides, decisions
docs/spec/   platform-neutral specification and test vectors (the master)
ios/         Swift app, with its own CLAUDE.md for platform rules
android/     Kotlin app, with its own CLAUDE.md for platform rules
```

The two apps are developed in separate working sessions, usually on separate computers. Each session works only in its own app directory and in `docs/`, on branches named `ios/<topic>` or `android/<topic>`, and merges into `main` through pull requests.

## Stages

1. **Foundation.** Service layer with background operation, configuration, connect and transmit as separate states, sensor selection and send rate, location, test area, jump to optiCLOUD.
2. **Device provisioning** through the REST API.
3. **Journal entries** with the offline queue.
4. **Photos.**

The leading app works through a stage first, and the following app catches up (see the decision on order). A stage is finished when both apps implement it and pass the shared test vectors.

## Working with the optiCLOUD source

The assistant working in this repository can read the private optiCLOUD source code to find out how communication works. This repository is public. Everything pushed here is visible to everyone, including its history.

- Never copy optiCLOUD source code, comments, or configuration into this repository.
- Never commit internal host names, credentials, tokens, keys, ticket references, or details of internal defects.
- Describe interfaces in your own words in `docs/spec/`: topics, endpoints, payloads, and behavior a client needs.
- Use only interfaces optiMEAS supports for customers. Once the app is public it documents the API in practice. If the source shows an internal or unstable endpoint, ask before using it.
- Signing keys, provisioning profiles, and local environment files stay out of the repository.

## Protocol facts

Read from the optiCLOUD source. Each one still needs a test against a running server before `docs/spec/` relies on it.

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
- Permission texts for location (including background), motion sensors, microphone, camera, and health data must say plainly why the app needs them.
- Health data needs the user's explicit consent and its own statements in both stores.
- The privacy declarations for both stores must list location, photos, user-written text, and health data.
- The app needs a screen with the open-source license notices.

## Answers from the optiCLOUD source

Read from the optiCLOUD source on 2026-10-12. None of this has been tested against a running server yet. Exact endpoints and payloads go into `docs/spec/`.

- **Tenants.** A user account can hold several roles, each bound to one tenant. Sign-in is a two-step exchange: the app sends the user name and password and receives the list of roles with their tenants, then signs in with the chosen role and receives an access token and a refresh token. A signed-in user can list their roles again and switch between them.
- **Sign-in methods.** There are three. Password sign-in is the basic one. Two-factor sign-in can be switched on per tenant and per role; the server then sends a code by e-mail, and the app confirms it in a separate step before it receives the tokens. Single sign-on uses OAuth2 / OpenID Connect providers configured on the server and ends with a one-time code that is exchanged for the tokens.
- **Registering a device.** The user needs the tenant administrator or tenant user role and the permission to create devices. The server generates the access token when it creates the device. Reading the token is a separate request with its own permission. The tenant's license can limit the number of devices; the server then refuses the registration.
- **Projects.** A tenant is divided into projects. A new device is placed in the project the user has currently selected and also in the tenant's root project.
- **Quality of service.** The server grants QoS 1 at most. It acknowledges a QoS 1 message only after it has accepted the message for processing, so an acknowledgment means the data arrived. A retry can produce duplicates.
- **Time stamps.** A telemetry message can carry its own time stamp and can hold several samples. Buffered data can therefore be delivered later with the original time stamps.
- **Dashboard URL.** A dashboard opens in the web application at `/dashboards/<dashboard id>` and the home view at `/home`. Both need a signed-in user. No URL addresses a tenant; the tenant comes from the signed-in session.
- **Notes.** A note belongs to an entity such as a device and has a name, a text, a status, and a priority. Writing one needs a signed-in user with the permission to create notes; the device access token is not enough.

## Open questions

1. How are general journal entries stored as notes? Writing a note needs a signed-in user today, and a general entry has none. This needs either a way for a device to write notes in optiCLOUD or another carrier for general entries.
2. How does a user sign in for personal journal entries? The user needs their own session, separate from the device access token and from the account that provisioned the device. The brief so far keeps session tokens only as long as provisioning needs them.
3. Who provides the dashboard widget for the latest photo of a series? The source has an image widget and a file explorer widget; a widget for the latest photo of a series was not found. Building it is work in optiCLOUD, not in this repository.
4. Can the app set the time stamp of a note? The source suggests the time comes from the request; this needs a test against a running server.
