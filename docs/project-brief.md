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
| Languages | Both apps are in German, English, French, Italian, and Spanish and follow the language of the phone; English is the fallback. The apps address the user informally where the language allows it (German "du", Italian "tu", Spanish "tú"; French "vous", as is usual on the platforms). Product and optiCLOUD terms such as Tenant, Shared Attribute, Access Token, and Dashboard stay as in the optiCLOUD documentation. Since 2026-10-25. |
| User manual | The user manual lives in `docs/manual/` in German, English, French, Italian, and Spanish, written for the optiMEAS documentation site (Docusaurus). German is the source of the French, Italian, and Spanish pages; English is maintained by hand. `docs/manual/scripts/sync-to-docusaurus.py` copies it into that site under optiCLOUD › Sensor App, where it also explains why the app is open source; the site is never edited directly. The manual is under CC BY 4.0 (attribution: optiMEAS GmbH and optiMEAS Switzerland GmbH); the code stays under MIT. A change to the app that the manual describes changes the manual in the same pull request. Since 2026-10-25. |
| Background | The app must keep transmitting in the background when the user has agreed to it. |
| Source | Open source in this public repository under the MIT license. All code in this repository is under the MIT license. Dependencies must have a permissive license compatible with it (MIT, BSD, Apache 2.0); no dependencies with copyleft (GPL, LGPL, EPL, MPL). This applies to everything that ships with an app. Tools used only to build or test the apps, such as JUnit, are exempt (since 2026-10-25). |
| Order | One app leads, the other follows. The leading app implements a stage first; the following app catches up from `docs/spec/`. The lead can change between the apps; a change is recorded here. **The iOS app leads since 2026-10-17.** Since 2026-10-25 the Android app does not follow in parallel: it catches up once the iOS app has reached a productive state. Each app is developed in its own working session and on its own branches. |
| Lead | The leading app settles open questions in `docs/spec/` and the shared test vectors, in the same pull request as its code. The following app implements from the specification, not by translating the other app's code, and solves platform questions such as background operation and design on its own. Behavior the following app finds missing or wrong in the specification goes into `docs/spec/` first, whichever app leads. |
| Master | The platform-neutral specification in `docs/spec/` is the master, not either app. Both apps are peers that implement it. |
| optiCLOUD API | The optiCLOUD source code is the reference for MQTT and REST behavior. See [Working with the optiCLOUD source](#working-with-the-opticloud-source). |
| Windows | A Windows desktop app is an idea for later (.NET rather than C++). It is not part of this plan. A PC has few sensors, so it would be a different product. |
| REST interfaces | optiMEAS supports the REST interfaces of the optiCLOUD web application for this app. |
| Sign-in | The app works only with a signed-in user. The user signs in with their personal optiCLOUD account (e-mail address, password, and the e-mail code if the tenant requires it) in a form inside the app, not in a browser. Then the user picks the tenant, the project, and the device, or creates a new device. The app reads the device access token itself; nobody handles tokens by hand. Since 2026-10-24. Single sign-on is a separate topic and not part of the stages below. |
| Session | The app keeps the user signed in by renewing the session. Telemetry runs on the device access token and goes on when the session expires or the user signs out; only the journal needs a session. |
| Devices of the app | Devices used by the app have the device type `optiCLOUD Sensor App`. The app creates devices with this type and offers only devices of this type. |
| One phone, one device | A device belongs to one phone; a new phone is a new device. The app binds a device to its phone through the shared attribute `sensorAppInstallation` and refuses to send to a device bound to another phone. A user with the right permission can take a device over after an explicit confirmation, for example after reinstalling the app. |
| Server address | The user enters only the address of the optiCLOUD web application. The MQTT endpoint is derived from it (same host, port 8883, TLS). There is no built-in list of installations, because optiCLOUD is hosted in many ways. |
| Data volume | Sending over the mobile network is always allowed; there is no Wi-Fi-only setting. The app counts its own data volume by mobile network and Wi-Fi, shows it for the day, the week, and the month, and sends the daily and monthly totals to optiCLOUD. |
| Support option | A hidden setting lets support enter the MQTT endpoint and a device access token by hand, without sign-in. |
| MQTT client | iOS: MQTTNIO 3.x (Apache 2.0); pinned to 3.0.0-rc.1 since 2026-10-25 until version 3 has a final release; since 2026-10-27 to the fork optimeas/mqtt-nio, which adds the fix for a crash when packets arrive after the connection closed (upstream issue #274, pull request #280), until a release has the fix. Android: HiveMQ MQTT Client 1.4.x (Apache 2.0). Chosen on 2026-10-24 after checking maintenance and licenses; Eclipse Paho is no longer maintained and CocoaMQTT has a copyleft license. |
| Platform versions | As new as possible. Both apps target the newest iOS and Android versions. The minimum versions are set in `ios/CLAUDE.md` and `android/CLAUDE.md`. On Android the minimum is API 31 (Android 12) since 2026-10-23, when a Samsung Galaxy A17 5G with Android 16 replaced the Galaxy S7 as the test device. On iOS the minimum is iOS 26 since 2026-10-25, the version of the test device, an iPhone 16 Pro Max. |
| Remote control | optiCLOUD may control the phone: the app accepts every RPC command, reacts to changes of shared attributes, and lets optiCLOUD set settings through them. |
| Sensors | The app offers every sensor the phone has, up to values measured on the body such as heart rate and body temperature. Values measured on the body come in a stage of their own, after the app is in productive use (see [Stages](#stages)). |
| Predecessor | The earlier "optiCLOUD Demo App" (Expo and React Native) stays in a private company repository. It is not a model for this product: nothing is derived from its code, design, specification, or history. |

## Functional areas

### Data the phone sends

- **Sensor values.** Whatever the device offers. The set differs from device to device, so the app discovers at run time what is available. This includes values measured on the body, such as heart rate and body temperature, which reach the phone from a watch or another device.
- **Location.** Geographic position, sent with the other data.
- **Journal entries.** Title and text written by the user, with status and priority. optiCLOUD stores them as notes of the signed-in user on the device. The time stamp of an entry is the moment the user saved it in the app, also when it is delivered later. optiCLOUD sets the time of a note itself, so the app sends the moment of saving, and the position if known, as additional information and adds the moment of saving to the text.
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
- the send rate, by default 2 seconds
- the send mode: by default only changed values, with a full sample every 60 seconds
- the address of the optiCLOUD web application, by default the official optiCLOUD server `https://dashboard.opticloud.io`
- an optional default dashboard

The details are in [docs/spec/configuration.md](spec/configuration.md).

The tenant, the project, and the device come from sign-in and device selection.

### Sign-in and device selection

Nobody handles tokens by hand. The details are in [docs/spec/sign-in.md](spec/sign-in.md).

1. The user enters the address of the optiCLOUD web application.
2. The user signs in with e-mail address and password. If the tenant requires two-factor sign-in, the user also enters the code sent by e-mail.
3. The user picks a tenant they have access to.
4. The user picks a project. The default project of the role is preselected; with only one project this step is skipped.
5. The user picks a device of the type `optiCLOUD Sensor App`, or creates a new one. For a new device the app proposes the phone's name.
6. The app binds the device to the phone, reads its access token, and stores it.

After that the user only has to connect and start transmitting.

### Favorites

The tab Favorites opens pages of the optiCLOUD web application in a browser view of the app, already signed in: first the default dashboard from the settings, or the home view of optiCLOUD if none is set; then the favorites the user keeps in the web application; then pages the user picks on the phone from the lists of dashboards and devices. Details in [docs/spec/favorites.md](spec/favorites.md).

## Architecture requirements

- **Background operation shapes the design from the first commit.** Sensor collection and MQTT run in a service layer that does not depend on the user interface, with its own reconnect logic.
  - iOS has no general "keep running" mode. The workable route is the location background mode with "Always" permission. Without that permission the app transmits only while it is open. App Review checks this mode closely, so location must be a visible feature with a clear permission text.
  - Android needs a foreground service with a persistent notification. Allowed service types and time limits have tightened in recent Android versions. Check them against the current target SDK.
- **Store and forward.** Journal entries and photos must not be lost without a network. They need a persistent queue that keeps the original time stamp. Telemetry is buffered as well while the phone is offline and is sent later with QoS 1 and its original time stamps, oldest first; the buffer holds up to 50 MB and drops the oldest samples when full. Details in [docs/spec/offline-queue.md](spec/offline-queue.md).
- **Photos do not travel over MQTT.** The message size is limited. The app uploads them through the device storage interface, which follows the S3 protocol and signs requests with the device access token.
- **Secrets.** The device access token, the refresh token of the user's session, and the installation identifier are stored in the Keychain (iOS) and the Keystore-backed storage (Android). The user's password is never stored.
- **Shared test vectors.** `docs/spec/` contains example payloads and expected results as JSON. Both apps run their protocol tests against the same files.

## Repository layout

```
docs/        this brief, setup guides, decisions
docs/spec/   platform-neutral specification and test vectors (the master)
docs/manual/ user manual in five languages, synced into the optiMEAS documentation
ios/         Swift app, with its own CLAUDE.md for platform rules
android/     Kotlin app, with its own CLAUDE.md for platform rules
```

The two apps are developed in separate working sessions, usually on separate computers. Each session works only in its own app directory and in `docs/`, on branches named `ios/<topic>` or `android/<topic>`, and merges into `main` through pull requests.

## Stages

1. **Foundation.** Sign-in and device selection through the REST API, service layer with background operation, configuration, connect and transmit as separate states, sensor selection and send rate, location, test area, favorites with the jump to optiCLOUD.
2. **Journal entries** with the offline queue.
3. **Photos.**
4. **Health data.** Values measured on the body, such as heart rate and body temperature, from the health store of the platform. This stage comes only after the app is in productive use and ships as a release of its own, because health data needs explicit consent, its own store statements, and a closer review by both stores.

The leading app works through a stage first, and the following app catches up (see the decision on order). A stage is finished when both apps implement it and pass the shared test vectors.

## Ideas

Ideas of the user, collected on 2026-10-27. None is planned or assigned to a stage yet.

- **Notes on the phone.** The app mirrors the notes from optiCLOUD, so that their whole history is on the phone, with older notes loaded on demand. Open: notes that belong to the tenant instead of a device, and which of them the app shows.
- **Messages from optiCLOUD.** optiCLOUD sends messages to the app, and the phone shows them as a banner. They can come from the rule engine, for example from rules the device keeps for itself, or from a person at a dashboard who sends one by hand. Open: how a message reaches the phone while the app is not running, which would need push notifications sent by optiCLOUD, and whether that is work in optiCLOUD.

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
- The MQTT client libraries are chosen (see [Decisions](#decisions)). Both are under Apache 2.0; the app shows their license texts and NOTICE files on its license screen.

## Before a store release

- Apple's reviewers need a working test account and device on an optiCLOUD server.
- Permission texts for location (including background), motion sensors, microphone, camera, and health data must say plainly why the app needs them.
- Health data needs the user's explicit consent and its own statements in both stores.
- The privacy declarations for both stores must list location, photos, user-written text, and health data.
- The app needs a screen with the open-source license notices.
- External testers and the store listing need a privacy policy URL; the privacy page of the user manual can serve once it is published.

## Answers from the optiCLOUD source

Read from the optiCLOUD source on 2026-10-12 and 2026-10-24. Exact endpoints and payloads go into `docs/spec/`.

On 2026-10-24 sign-in with a role, renewing the session, the project tree, creating a device, reading its access token, writing a shared attribute, MQTT over TLS on port 8883 with the device token, telemetry with time stamps, client attributes, attribute requests, and notes were tested against an optiCLOUD test server with a tenant administrator. Two-factor sign-in, users with restricted rights, commands, and alarms are not yet tested.

- **Tenants.** A user account can hold several roles, each bound to one tenant. Sign-in is a two-step exchange: the app sends the user name and password and receives the list of roles with their tenants, then signs in with the chosen role and receives an access token and a refresh token. A signed-in user can list their roles again and switch between them.
- **Sign-in methods.** There are three. Password sign-in is the basic one. Two-factor sign-in can be switched on per tenant and per role; the server then sends a code by e-mail, and the app confirms it in a separate step before it receives the tokens. Single sign-on uses OAuth2 / OpenID Connect providers configured on the server and ends with a one-time code that is exchanged for the tokens.
- **Registering a device.** The user needs the tenant administrator or tenant user role and the permission to create devices. The server generates the access token when it creates the device. Reading the token is a separate request with its own permission. The tenant's license can limit the number of devices; the server then refuses the registration.
- **Projects.** A tenant is divided into projects in a tree. A session works in one project at a time, at first the default project of the role. A new device is placed in the project of the session and also in the tenant's root project. Reading a device's access token works only for devices in the project of the session.
- **Quality of service.** The server grants QoS 1 at most. It acknowledges a QoS 1 message only after it has accepted the message for processing, so an acknowledgment means the data arrived. A retry can produce duplicates.
- **Time stamps.** A telemetry message can carry its own time stamp and can hold several samples. Buffered data can therefore be delivered later with the original time stamps.
- **Dashboard URL.** A dashboard opens in the web application at `/dashboards/<dashboard id>` and the home view at `/home`. Both need a signed-in user. No URL addresses a tenant; the tenant comes from the signed-in session.
- **Notes.** A note belongs to an entity such as a device and has a name, a text, a status, and a priority. Writing one needs a signed-in user with the permission to create notes; the device access token is not enough. The server sets the time of a note itself and ignores a time sent by the client; free additional information is kept. Notes cannot be deleted one by one.
- **Device types.** optiCLOUD has no device profiles. Each device has a free-text type, and the device list cannot be filtered by it on the server.
- **Several connections per device.** The server accepts several MQTT connections with the same device token at the same time and cannot tell them apart.
- **MQTT endpoint.** No interface tells a client the MQTT host and port. Installations offer MQTT over TLS on port 8883 of the web application's host by convention.
- **Alarms.** An alarm can carry an identifier chosen by the client; a later `CLEARED` with the same identifier ends exactly that alarm. Without it the server matches by the kind of alarm.

## Open questions

1. Who provides the dashboard widget for the latest photo of a series? The source has an image widget and a file explorer widget; a widget for the latest photo of a series was not found. Building it is work in optiCLOUD, not in this repository.
2. optiMEAS is asked to extend notes in optiCLOUD: a time stamp set by the client, and a history that shows which user changed a note when. Until then the app carries the moment of saving in the additional information and in the text.
3. optiMEAS is asked for a supported way to open a page of the web application signed in, with a return address. Until then the app hands its session to a browser view in a way that depends on internal behavior of the web application (see [docs/spec/favorites.md](spec/favorites.md#opening-a-page)).
4. On the test server, alarm messages were not acknowledged and the alarms were not found (2026-10-24). This needs to be cleared up before the app relies on alarms.
5. Two-factor sign-in and users with restricted rights still need a test, with a second test account that is not a tenant administrator.
