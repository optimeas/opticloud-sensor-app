# Connection

**Status: draft.** Not yet tested against a server.

The app talks to optiCLOUD as a device over MQTT. This document describes how it connects, which states it has, and how it recovers from a lost connection. The messages themselves are in [messages.md](messages.md).

## Endpoint

- The endpoint is a host name and a port from the settings.
- The transport is MQTT 3.1.1 over TLS. The default port is 8883.
- The app must verify the server certificate against the system trust store. It must not offer a setting that switches this check off.
- The app must not connect without TLS.

## Signing on as a device

The device identifies itself with its access token.

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
| Not authorized | The token is unknown or disabled | Stops and reports that the token was refused |
| Server unavailable | The server could not check the token | Retries as after a lost connection |

After "bad user name or password" and "not authorized" the app must not retry on its own. A retry needs a changed setting or an action by the user.

## Subscriptions

After the connect was accepted, the app subscribes with QoS 1 to:

| Topic filter | Purpose |
| --- | --- |
| `v2/json/devices/me/attributes` | Changes of shared attributes |
| `v2/json/devices/me/attributes/response/+` | Answers to attribute requests |
| `v2/json/devices/me/rpc/request/+` | Commands from the server |

The app is connected when the server has confirmed all three subscriptions. If the server refuses one, the app disconnects and treats this as a lost connection.

The server accepts only these exact filters. It grants QoS 1 at most.

## States

Connection and transmission are two separate states with separate controls.

### Connection

| State | Meaning |
| --- | --- |
| Disconnected | No connection and no attempt. The initial state. |
| Connecting | The app is opening the connection, signing on, or subscribing. |
| Connected | The subscriptions are confirmed. |
| Waiting | The connection was lost or failed. The app retries after a delay. |
| Refused | The server refused the token. The app does not retry. |

- The user starts with "connect": Disconnected or Refused → Connecting.
- The user stops with "disconnect": any state → Disconnected. The app sends DISCONNECT if a connection exists.
- The wish to be connected is a setting. It survives a restart of the app.

### Transmission

| State | Meaning |
| --- | --- |
| Off | The app sends no sensor values on its own. |
| On | The app samples the selected sensors at the send rate and sends the values. |

- Transmission is switched on and off by the user. It is a setting and survives a restart.
- Transmission only sends while the connection state is Connected. While it is not, the samples go to the offline queue.
- Disconnecting does not switch transmission off, and switching transmission off does not disconnect.
- The test area works whenever the connection state is Connected, whether transmission is on or off.

## Keeping the connection alive

- The app sends a PINGREQ when it has sent nothing for the keep-alive time.
- The server does not close a silent connection on its own. The app must therefore detect a dead connection itself: if a PINGRESP does not arrive within 20 seconds, the app closes the connection and treats it as lost.

## Reconnecting

When the connection is lost or an attempt fails, the app goes to Waiting and retries:

- The delay starts at 1 second and doubles with every failed attempt, up to 60 seconds.
- Each delay is varied at random by up to 20 percent, so that many phones do not reconnect at the same moment.
- A successful connect resets the delay.
- When the operating system reports that the network is back, the app retries at once.

The service layer does this without the user interface, also in the background.

## Open points

1. Does the app need a second endpoint setting for the REST interface and the web application, or is it derived from the MQTT host name?
2. Should the app show the reason for Waiting (no network, server not reachable, certificate not trusted) as separate conditions?
3. Is 60 seconds the right keep-alive for background operation on a mobile network, or should it be longer to save battery?
