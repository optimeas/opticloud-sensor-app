# Connection

**Status: draft.** Signing on with a device token, the subscriptions, and an attribute request were tested against an optiCLOUD test server on 2026-10-24. On 2026-10-25 the iOS app connected, checked the binding, published its client attributes, and delivered telemetry from the offline queue on the test server. The other results of signing on are not yet tested.

The app talks to optiCLOUD as a device over MQTT. This document describes how it connects, which states it has, and how it recovers from a lost connection. The messages themselves are in [messages.md](messages.md).

## Endpoint

- The user enters one address: the address of the optiCLOUD web application, for example `https://cloud.example.com`. It must start with `https://`.
- The REST interface is at this address (see [sign-in.md](sign-in.md)).
- The MQTT endpoint is derived from it: the same host name, port 8883. optiCLOUD has no interface that tells a client its MQTT endpoint, and port 8883 with TLS is the convention of optiCLOUD installations.
- The hidden support option (see [sign-in.md](sign-in.md#support-option)) can set host name and port of the MQTT endpoint by hand.
- The transport is MQTT 3.1.1 over TLS. The server does not support MQTT 5.
- The app must verify the server certificate against the system trust store. It must not offer a setting that switches this check off.
- The app must not connect without TLS.

## Signing on as a device

The device identifies itself with its access token. The app reads the token after the user has picked the device (see [sign-in.md](sign-in.md#reading-the-access-token)).

| CONNECT field | Value |
| --- | --- |
| User name | The device access token |
| Password | Not sent |
| Client identifier | A random UUID that the app creates once and keeps |
| Clean session | Set |
| Keep alive | 60 seconds |
| Will message | None |

The server keeps no session between connections. After every successful connect the app must subscribe again.

The server answers with one of these results:

| Result | Meaning | What the app does |
| --- | --- | --- |
| Accepted | The token is valid | Continues with the subscriptions |
| Bad user name or password | No token was sent | Stops and reports a configuration error |
| Not authorized | The token is unknown or disabled, or the tenant has expired | Stops and reports that the token was refused |
| Server unavailable | The server could not check the token | Retries as after a lost connection |

After "bad user name or password" and "not authorized" the app must not retry on its own. A retry needs a changed setting or an action by the user.

## Subscriptions

After the connect was accepted, the app subscribes with QoS 1 to:

| Topic filter | Purpose |
| --- | --- |
| `v2/json/devices/me/attributes` | Changes of shared attributes |
| `v2/json/devices/me/attributes/response/+` | Answers to attribute requests |
| `v2/json/devices/me/rpc/request/+` | Commands from the server |

If the server refuses one, the app disconnects and treats this as a lost connection.

The server accepts only these exact filters. It grants QoS 1 at most.

## Checking the binding

After the subscriptions are confirmed, the app requests the shared attribute `sensorAppInstallation` together with the other shared attributes it uses (see [messages.md](messages.md#requesting-attributes)) and compares it with its installation identifier (see [sign-in.md](sign-in.md#binding-to-the-phone)).

| Answer | What the app does |
| --- | --- |
| Same identifier | The app is connected. |
| Other identifier | The app disconnects, switches transmission off, and goes to Refused with the reason "bound to another phone". |
| Missing | If the user is signed in, the app binds the device through the REST interface and is connected. Otherwise it disconnects and goes to Refused with the reason "not bound". |
| No answer | The app treats this as a lost connection. |

The app is connected when the subscriptions are confirmed and the binding is checked. When a change of `sensorAppInstallation` arrives later with another identifier, the app acts as for "other identifier". In the support mode the app does not check the binding.

## States

Connection and transmission are two separate states with separate controls.

### Connection

| State | Meaning |
| --- | --- |
| Disconnected | No connection and no attempt. The initial state. |
| Connecting | The app is opening the connection, signing on, or subscribing. |
| Connected | The subscriptions are confirmed. |
| Waiting | The connection was lost or failed. The app retries after a delay. |
| Refused | The server refused the token, or the device belongs to another phone. The app does not retry. |

The app shows why it is waiting or refused, as one of these reasons:

| State | Reason |
| --- | --- |
| Waiting | No network |
| Waiting | Server not reachable |
| Waiting | Certificate not trusted |
| Waiting | Connection lost |
| Refused | Token refused |
| Refused | Bound to another phone |
| Refused | Not bound |

The reason is also shown in the test area, with the time it occurred.

- The user starts with "connect": Disconnected or Refused → Connecting.
- The user stops with "disconnect": any state → Disconnected. The app sends DISCONNECT if a connection exists.
- The wish to be connected is a setting. It survives a restart of the app.

### Transmission

| State | Meaning |
| --- | --- |
| Off | The app sends no sensor values on its own. |
| On | The app samples the selected sensors at the send rate and sends the values. |

- Transmission is switched on and off by the user. It is a setting and survives a restart.
- Every sample goes through the [offline queue](offline-queue.md). The queue is delivered while the connection state is Connected; while it is not, samples wait there.
- Disconnecting does not switch transmission off, and switching transmission off does not disconnect.
- The test area works whenever the connection state is Connected, whether transmission is on or off.

## Keeping the connection alive

- The app sends a PINGREQ when it has sent nothing for the keep-alive time of 60 seconds. The server ends a session that has shown no activity for five minutes, so the keep-alive must stay well below that.
- The server does not close a silent connection on its own. The app must therefore detect a dead connection itself: if a PINGRESP does not arrive within 20 seconds, the app closes the connection and treats it as lost.

## Reconnecting

When the connection is lost or an attempt fails, the app goes to Waiting and retries:

- The delay starts at 1 second and doubles with every failed attempt, up to 60 seconds.
- Each delay is varied at random by up to 20 percent, so that many phones do not reconnect at the same moment.
- A successful connect resets the delay.
- When the operating system reports that the network is back, the app retries at once.

The service layer does this without the user interface, also in the background.

## Data volume

The app counts its own data volume, so that the user and optiCLOUD can see what it costs. Neither platform offers a count per app on both systems, so both apps count the same way:

- The app counts the bytes of every MQTT packet it sends and receives, and of every REST request and answer, with headers.
- For the overhead of TLS, TCP, and IP it adds 80 bytes per MQTT packet and per REST request and answer. The result is an estimate, and the app shows it as such.
- It counts by network: mobile network or Wi-Fi, as the operating system reports it at that moment. Other networks count as Wi-Fi.
- It keeps counters per day in the local time of the phone.

The app shows sent and received data for today, this week (from Monday), and this month, separately for mobile network and Wi-Fi. The item `dataVolume` of the group `device` sends the totals for today and for the month to optiCLOUD (see [sensors.md](sensors.md#device)).

## Open points

None at the moment.
