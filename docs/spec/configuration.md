# Configuration

**Status: draft.**

This document lists the settings of the app, their defaults, and their allowed values. A setting keeps its value until the user or optiCLOUD changes it, also across a restart of the app.

## Settings

| Setting | Default | Allowed values | Changed by |
| --- | --- | --- | --- |
| Address of the web application | `https://dashboard.opticloud.io` | An address that starts with `https://` | User, before sign-in |
| Tenant, project, device | None | What the signed-in user can choose | User, after sign-in (see [sign-in.md](sign-in.md)) |
| Send rate | 2 s | Whole seconds from 1 to 3600 | User, shared attribute `sendRate`, command `setSendRate` |
| Send mode | On change | On change, every tick | User |
| Sensor selection | `device,location` | Group and item keys from the catalog (see [sensors.md](sensors.md#selection)) | User, shared attribute `sensors` |
| Default dashboard | None | The identifier of a dashboard | User, shared attribute `dashboard` |
| Connected | Off | On, off | User |
| Transmission | Off | On, off | User, commands `startTransmission` and `stopTransmission` |

- `https://dashboard.opticloud.io` is the official optiCLOUD server of optiMEAS. Other installations are entered by hand.
- The tenant, the project, and the device are offered only after sign-in. Until a device is picked, the app cannot connect.
- The send modes are described in [sensors.md](sensors.md#sending-on-change).
- The default dashboard is the first entry of the tab Favorites (see [favorites.md](favorites.md)). Without one, that entry opens the home view (`/home`). With one, it opens `/dashboards/<identifier>`.
- A setting whose shared attribute exists is managed by optiCLOUD and locked on the phone (see [messages.md](messages.md#changes-of-shared-attributes)). A command that would change a managed setting is answered with `managed setting`.
- A value outside the allowed values is refused: on the phone the user cannot enter it, from optiCLOUD it is ignored and shown in the test area.

## Stored data

Besides the settings, the app keeps:

| Data | Where | Kept until |
| --- | --- | --- |
| Device access token | Keychain (iOS), Keystore-backed storage (Android) | Another device is picked |
| Refresh token of the user's session | Keychain, Keystore-backed storage | The user signs out or the session expires |
| Installation identifier | Keychain, Keystore-backed storage | The app is removed (see [sign-in.md](sign-in.md#binding-to-the-phone)) |
| Counters of the data volume | App storage | The end of the following month |

The password of the user is never stored.

## Signing out and changing the device

- Signing out deletes the session tokens. The device, its token, and all settings stay, and transmission goes on.
- Picking another device replaces the device token. The settings stay; shared attributes of the new device apply from the next connect.
- Changing the address of the web application signs the user out and forgets the device, because the device belongs to the old server. The app switches transmission off and disconnects before.

## Support option

The hidden support option (see [sign-in.md](sign-in.md#support-option)) adds two settings: host name and port of the MQTT endpoint, and a device access token entered by hand. While they are set, they replace the endpoint derived from the address and the token from device selection.
