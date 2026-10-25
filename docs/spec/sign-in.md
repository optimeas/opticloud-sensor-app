# Sign-in and device selection

**Status: draft.** The steps were tested against an optiCLOUD test server on 2026-10-24 with a tenant administrator. On 2026-10-25 the iOS app went through the whole flow against the test server with a tenant administrator: sign-in, tenant, project, creating a device, binding, and reading the access token. On 2026-10-25 the Android app went through the flow against the production server with an administrator whose account also has a role without tenant. Two-factor sign-in and users with restricted rights are not yet tested.

The app works only with a signed-in user. The user signs in with their personal optiCLOUD account, picks a tenant and a project, and then picks the device the phone sends to, or creates a new one. The app reads the access token of that device and uses it for MQTT (see [connection.md](connection.md)). The user's session also carries the journal (see [journal.md](journal.md)).

All requests in this document go to the REST interface of optiCLOUD at the address of the web application (see [connection.md](connection.md#endpoint)). Bodies and answers are JSON.

An identifier in an answer, such as the `id` of a project or a device, is an object with the member `id`, for example `{ "entityType": "DEVICE", "id": "…" }`. The app reads `id` and ignores the other members. It also accepts an identifier written as a plain string. In a request path or body, the app writes the plain `id`.

## Overview

1. The user enters the address of the web application.
2. The user enters e-mail address and password.
3. The user picks a tenant.
4. If the tenant requires it, the user enters the code sent by e-mail.
5. The user picks a project.
6. The user picks a device or creates a new one.
7. The app binds the device to this phone and reads its access token.

After that the user only has to connect and switch transmission on.

## Sign-in

### Tenants

The app sends e-mail address and password to `POST /api/noauth/authorization`:

```json
{ "username": "user@example.com", "password": "…" }
```

The answer lists the user's roles. Each role belongs to one tenant:

```json
[
  {
    "authorityId": { "id": "…" },
    "authority": "TENANT_USER",
    "tenant": { "id": "…", "name": "Example" },
    "enabled": true,
    "projectCount": 3
  }
]
```

- This step issues no token.
- A role can lack `tenant`, for example the role of a system administrator; the production server lists such a role (seen on 2026-10-25). The app cannot work with it.
- The app offers the roles whose `enabled` is true and that have a `tenant`, by tenant name. If there is only one, the app picks it without asking. If there is none, the app says that the account has no access to a tenant.
- A wrong password is answered with an error (see [Errors](#errors)). An unknown e-mail address is answered with status 400 and a body without `errorCode` (seen on the test server on 2026-10-25). The app treats both as "sign-in failed".

### Signing in with a role

The app signs in with the chosen role at `POST /api/auth/login`:

```json
{ "username": "user@example.com", "password": "…", "authorityId": "…" }
```

The answer is one of two forms:

- Signed in: `{ "token": "…", "refreshToken": "…", "twoFactorRequired": false }`
- Code required: `{ "twoFactorRequired": true, "twoFactorToken": "…", "twoFactorEmail": "…" }`

The app keeps the password in memory only until this step is finished, and never stores it.

### Code by e-mail

If a code is required, the server has already sent it to the address in `twoFactorEmail`. The app shows that address and asks for the code. It confirms the code at `POST /api/noauth/2fa/verify`:

```json
{ "twoFactorToken": "…", "code": "123456" }
```

- The answer is the signed-in form above.
- A code is valid for a few minutes and allows a few attempts only.
- To get a new code, the app repeats the sign-in with the role. There is no separate request for it.

### The session

- Every further request sends the access token in the header `X-Authorization: Bearer <token>`.
- The access token is a JWT. Among its claims are `tenantId`, `projectId`, `userId`, and `authorityDataId` (the role). The app reads them from the token and does not ask the server for them.
- The access token is short-lived (one hour on the test server). The app renews it before it expires: before a request, if the token expires within the next 2 minutes according to its claim `exp`. It renews at `POST /api/auth/token` with `{ "refreshToken": "…" }`. The answer is a new access token and a new refresh token.
- Every renewal extends the session. As long as the app renews in time, the user stays signed in. When the refresh token has expired, the user signs in again.
- The app stores the refresh token in the Keychain (iOS) or in Keystore-backed storage (Android). It never writes tokens to logs.
- An expired session does not stop transmission: telemetry uses the device access token, not the user's session. Journal entries wait in the queue until the user has signed in again.
- Signing out deletes both tokens on the phone. The server does not invalidate them, so the app must forget them itself. Signing out does not stop transmission and does not release the device.

## Project

A tenant is divided into projects in a tree. The session works in one project at a time.

- After sign-in the session is in the default project of the role.
- The app lists the projects the role can use with `GET /api/projects/enabled`. The answer is a tree: each project has `id`, `name`, and `children`.
- If there is only one project, the app skips this step. Otherwise it offers the tree with the default project preselected.
- To change the project, the app calls `POST /api/auth/selectProject/<projectId>`. The answer is a new token pair, which replaces the old one.

The device list, the creation of devices, and reading the access token all refer to the project of the session.

## Device

### Marking devices of the app

Devices that the app uses have the device type **`optiCLOUD Sensor App`**. The app creates new devices with this type and offers only devices of this type. This keeps the phone from writing into a device that belongs to a machine.

### Listing devices

The app lists the devices with `GET /api/tenants/<tenantId>/devices?projectId=<projectId>&limit=<n>&page=<p>`.

- An optional `textSearch` filters by the start of the name, without regard to case.
- The answer is a page: `{ "data": [ … ], "hasNext": true }`. Pages are counted from 0.
- Each device has the members `id`, `name`, and `type`, and can have a `label`. The app shows the name.
- The server cannot filter by type. The app keeps only devices whose `type` is `optiCLOUD Sensor App`.
- For each device the app reads the binding (see [Binding](#binding-to-the-phone)) and shows devices bound to another phone as not available.

### Creating a device

The app creates a device with `POST /api/devices`:

```json
{ "name": "Anna's iPhone", "type": "optiCLOUD Sensor App" }
```

- The app proposes the name of the phone. The user can change it. On iOS an app gets only the model name, such as “iPhone”, so the proposal is that.
- The name must be unique within the tenant. Otherwise the server refuses it, and the app asks for another name.
- The device is created in the project of the session and is also linked to the root project of the tenant.
- The tenant's license can limit the number of devices. The server then refuses the device, and the app says so.
- The server creates the access token of the device together with the device.

### Reading the access token

The app reads the credentials with `GET /api/device/<deviceId>/credentials`:

```json
{ "credentialsType": "ACCESS_TOKEN", "credentialsId": "<token>", "enabled": true }
```

- The token is `credentialsId`.
- If `credentialsType` is not `ACCESS_TOKEN`, for example an X.509 certificate, the app cannot use the device and says so.
- If `enabled` is false, the device is blocked, and the app says so.
- Reading credentials needs its own permission. A user without it cannot use the app to set up a device.
- The app stores the token in the Keychain or Keystore-backed storage.

## Binding to the phone

A device in optiCLOUD belongs to one phone. A new phone is always a new device. optiCLOUD itself cannot tell two phones with the same token apart, so the app enforces this.

- On its first start the app creates a random UUID, the **installation identifier**, written in lower case with hyphens, and stores it in the Keychain or Keystore-backed storage.
- The binding is the shared attribute **`sensorAppInstallation`** of the device. Its value is the installation identifier of the phone the device belongs to.
- The app writes it through the user's session with `POST /api/plugins/telemetry/DEVICE/<deviceId>/attributes/SHARED_SCOPE` and the body `{ "sensorAppInstallation": "<installation identifier>" }`.
- The app reads it with `GET /api/plugins/telemetry/DEVICE/<deviceId>/values/attributes/SHARED_SCOPE`. The answer is a list of `{ "key", "value", "lastUpdateTs" }`.

Rules:

- When the app creates a device, it binds it at once.
- When the user picks an existing device without binding, the app binds it.
- A device bound to this phone can be picked again, for example after signing in anew.
- A device bound to another phone cannot be picked. The user can **take it over** after an explicit confirmation that names the risk: the other phone stops sending to this device. Taking over overwrites the binding. It needs the permission to change shared attributes. This covers a reinstalled app, whose installation identifier is new.
- An administrator releases a device by deleting the attribute in optiCLOUD.
- On every connect the app checks the binding over MQTT (see [connection.md](connection.md#checking-the-binding)).

The binding protects against mistakes, not against intent: a client that knows the token can ignore it.

## Tenant and device changes

- Changing the tenant or the project means picking a device again. The app switches transmission off and disconnects before.
- Picking another device replaces the stored token. The old device keeps its binding to this phone until an administrator releases it or the phone takes it over again.

## Support option

For support, a hidden setting lets a person enter the MQTT endpoint and a device access token by hand, without signing in. In this mode the journal is not available, and the app does not check the binding.

## Errors

The server answers errors with a JSON object:

```json
{ "status": 400, "message": "Device with such name already exists!", "errorCode": 31 }
```

The app decides by `errorCode` and shows its own text. It shows `message` only as a detail for support.

- `status` is not reliable: some answers write it as a number, others as a name, for example `{ "status": "UNAUTHORIZED", "message": "Authentication failed", "errorCode": 10 }` from `POST /api/auth/login` on the test server (2026-10-25). The app must read `errorCode` and `message` also when `status` is a name, and takes the status from the HTTP response.
- An error body can lack `errorCode`. The app then decides by the HTTP status and the request.
- After several failed attempts the server locks the account. `POST /api/noauth/authorization` then answers with status 500 and a `message` that says so, without `errorCode` 33 (seen on the test server on 2026-10-25). The app shows its general error text with the server's `message` as the detail; it does not decide by the wording of `message`. An administrator unlocks the account.

| `errorCode` | Meaning | What the app does |
| --- | --- | --- |
| 10 | Sign-in failed | Asks for e-mail address and password again |
| 11 | The access token has expired | Renews the session and repeats the request once |
| 12 | The account or the tenant has expired | Shows it and stops |
| 14 | A license limit is reached, for example the number of devices | Shows it |
| 20 | The permission is missing | Names the step that failed |
| 31 | The request is not valid, for example a duplicate name | Shows it at the field concerned |
| 33 | Too many attempts, for example with the e-mail code | Asks the user to sign in again later |

## Open points

1. Two-factor sign-in is not yet tested. In particular: does renewing the session of a role with two-factor sign-in need a new code?
2. Which permissions does a normal user need at least: listing devices, creating devices, reading credentials, writing shared attributes, writing notes? To be tested with a user who is not a tenant administrator.
