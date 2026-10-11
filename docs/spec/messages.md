# Messages

**Status: draft.** Not yet tested against a server.

This document describes the MQTT messages between the app and optiCLOUD. How the connection is made is in [connection.md](connection.md).

## General rules

- Every topic addresses the device that owns the connection. Topics do not contain a device name.
- The app publishes with QoS 1. A message counts as delivered when the server has acknowledged it. The server acknowledges only after it has accepted the message for processing.
- A message that was sent twice can be stored twice. The app must not send a message again after it was acknowledged.
- An MQTT packet must not be larger than 64 KiB. The app keeps a payload at or below 32 KiB and splits larger batches.
- A request identifier is a positive whole number at the end of a topic. The app counts it up from 1 for every connection.
- The app must ignore object members it does not know.
- Keys of telemetry values and attributes, and names of commands, are written in lower camel case, for example `batteryLevel`.

### Errors

The server has no way to refuse a single message.

- If the server cannot read a payload, it closes the connection. The app must therefore never send a payload that does not follow this document. A payload that led to a closed connection must not be sent again without change.
- If the app publishes to a topic the server does not know, the server acknowledges the message and drops it.

## Overview

| Purpose | Direction | Topic |
| --- | --- | --- |
| Telemetry | app → server | `v2/json/devices/me/telemetry` |
| Client attributes | app → server | `v2/json/devices/me/attributes` |
| Shared attribute changes | server → app | `v2/json/devices/me/attributes` |
| Attribute request | app → server | `v2/json/devices/me/attributes/request/<id>` |
| Attribute response | server → app | `v2/json/devices/me/attributes/response/<id>` |
| Command (RPC request) | server → app | `v2/json/devices/me/rpc/request/<id>` |
| Command answer (RPC response) | app → server | `v2/json/devices/me/rpc/response/<id>` |
| Alarms | app → server | `v3/json/devices/me/alarms` |

## Telemetry

A telemetry message is an array of samples. A sample has a time stamp and one or more values:

```json
[
  { "ts": 1760000000000, "values": { "batteryLevel": 0.82, "charging": false } },
  { "ts": 1760000001000, "values": { "batteryLevel": 0.82 } }
]
```

- `ts` is the moment the value was measured, not the moment it is sent.
- The app always sends this form, also for a single sample.
- Samples in one message are ordered by rising `ts`.
- A value is a number, a boolean, or a string. The app must not send `null`, an object, or an array as a value.
- A number that is not finite cannot be sent. The app leaves that key out of the sample. A sample without values is not sent.

## Attributes

### Client attributes

The app publishes client attributes as one flat object:

```json
{ "appVersion": "1.0.0", "osVersion": "27.0" }
```

The rules for values are the same as for telemetry. Attributes have no time stamp; the server keeps the latest value.

The app publishes these attributes after every successful connect and again when one of them changes:

| Key | Type | Meaning |
| --- | --- | --- |
| `appVersion` | string | Version of the app |
| `os` | string | `iOS` or `Android` |
| `osVersion` | string | Version of the operating system |
| `model` | string | Model of the phone |
| `sensorsAvailable` | string | Keys of the sensor groups this phone offers, separated by commas. See [sensors.md](sensors.md). |
| `sensors` | string | Keys of the sensor groups that are selected for transmission, separated by commas |
| `sendRate` | number | The send rate in effect, in seconds |
| `transmitting` | boolean | Whether transmission is on |

With these optiCLOUD can show what the phone offers and what it currently does.

### Changes of shared attributes

When a shared attribute changes on the server, the app receives:

```json
{ "shared": { "sendRate": 5, "oldKey": null } }
```

A key with the value `null` was deleted.

optiCLOUD controls settings of the app through these shared attributes:

| Key | Type | Setting |
| --- | --- | --- |
| `sendRate` | number | The send rate in seconds |
| `sensors` | string | Keys of the sensor groups to transmit, separated by commas |
| `dashboard` | string | Identifier of the default dashboard for the jump to optiCLOUD |

- A setting whose shared attribute exists is managed by optiCLOUD. The app applies the value, shows the setting as managed, and does not let the user change it.
- When the shared attribute is deleted, the setting keeps its last value and the user can change it again.
- A value the app cannot use (wrong type, outside the allowed range, unknown sensor group) is ignored. The setting keeps its value, and the app shows the problem in the test area.
- After every successful connect the app requests these three shared attributes, because it does not learn about changes made while it was offline.
- Every change of a shared attribute is shown in the test area, also for keys the app does not use.

### Requesting attributes

The app asks for current values by publishing to the request topic:

```json
{ "clientKeys": "appVersion", "sharedKeys": "sendRate,dashboard" }
```

- Both members are optional. The keys are one string, separated by commas. They are not a JSON array.
- The answer arrives on the response topic with the same identifier:

```json
{ "client": { "appVersion": "1.0.0" }, "shared": { "sendRate": 5 } }
```

- A key that does not exist is missing in the answer. A scope without any result can be missing as a whole.
- If no answer arrives within 10 seconds, the request has failed. The app may repeat it with a new identifier.

## Commands

The server sends a command as an RPC request. The identifier is only in the topic:

```json
{ "method": "ping", "params": {} }
```

- `method` is a string. `params` can be any JSON value and can be missing.
- The app accepts every command: it shows it in the test area and answers it by publishing to the response topic with the same identifier. The payload of the answer is a JSON object.
- The server waits only a limited time for the answer. The app should answer within 5 seconds.
- A command is delivered only while the app is connected. The app must not expect commands that were sent while it was offline.

The app carries out these commands:

| Method | Parameters | Effect | Answer |
| --- | --- | --- | --- |
| `ping` | none | None | `{ "pong": true }` |
| `getState` | none | None | `{ "transmitting": false, "sendRate": 5, "sensors": "motion,location" }` |
| `startTransmission` | none | Switches transmission on | `{ "transmitting": true }` |
| `stopTransmission` | none | Switches transmission off | `{ "transmitting": false }` |
| `setSendRate` | `{ "seconds": 5 }` | Changes the send rate | `{ "sendRate": 5 }` |

A command that cannot be carried out is answered with an error and changes nothing:

```json
{ "error": "unknown method" }
```

| Error | Cause |
| --- | --- |
| `unknown method` | The app does not carry out this method |
| `invalid params` | Parameters are missing, have the wrong type, or are outside the allowed range |
| `managed setting` | The setting is managed through a shared attribute |

## Alarms

The app reports alarms as a batch:

```json
{
  "alarms": [
    {
      "context": "manual",
      "level": "WARNING",
      "status": "ACTIVE",
      "raiseTime": 1760000000000,
      "message": "Raised in the test area"
    }
  ]
}
```

| Member | Required | Meaning |
| --- | --- | --- |
| `context` | yes | The kind of alarm, a string |
| `level` | yes | `CRITICAL`, `MAJOR`, `MINOR`, `WARNING`, `SERVICE`, `ACTION`, or `INDETERMINATE` |
| `status` | yes | `ACTIVE` when the alarm is raised, `CLEARED` when it is over |
| `raiseTime` | no | The moment the alarm was raised |
| `releaseTime` | no | The moment the alarm was cleared |
| `message` | no | A text for the user |

- The app sends `raiseTime` with `ACTIVE` and `releaseTime` with `CLEARED`.
- If one of the required members is missing or has another value than listed, the server closes the connection.

## Open points

1. How does the server match a `CLEARED` alarm to the earlier `ACTIVE` one: by `context` alone, or does the app have to send an identifier? This needs a look at the source and a test.
2. Are the limits right: 32 KiB per payload, 10 seconds for an attribute response, 5 seconds for a command answer?
3. Is "managed by optiCLOUD" the right rule when a shared attribute and a setting on the phone disagree, or should the last change win?
4. Should transmission also be controllable through a shared attribute, in addition to the two commands?
5. Which further commands are needed, for example to take a photo or to request a single value?
