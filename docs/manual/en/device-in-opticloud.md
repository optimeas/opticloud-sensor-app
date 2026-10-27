---
title: The device in optiCLOUD
description: Telemetry, client attributes, shared attributes, and commands of a device of the optiCLOUD Sensor app.
sidebar_label: The device in optiCLOUD
sidebar_position: 6
image: "/img/om_social_card.png"
keywords:
  - device
  - telemetry
  - client attribute
  - shared attributes
  - RPC
last_update:
  date: 2026-10-27
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# The device in optiCLOUD

For optiCLOUD your phone is a device like any other. You find it in the chosen project under its name, with the device type "optiCLOUD Sensor App". You use its values in dashboards, alarm rules, and reports like those of any other device.

## Telemetry

The measured values arrive as telemetry. Every value has the time stamp at which it was measured, not the one at which it was sent. Values from the offline queue therefore appear at the right place in the time series. Which keys exist is in [Sensors](sensors.md).

## Client attributes

After every connect and with every change, the app reports what the phone is and what it is currently doing:

| Key | Content |
|---|---|
| `appVersion` | Version of the app |
| `os` | `iOS` or `Android` |
| `osVersion` | Version of the operating system |
| `model` | Model of the phone, for example `iPhone 16 Pro Max` |
| `sensorsAvailable` | The values this phone offers |
| `sensors` | The values currently selected |
| `sendRate` | The send rate in seconds |
| `transmitting` | Whether the phone is currently sending |

`sensorsAvailable` and `sensors` are lists of groups and values, separated by commas, for example `device,location,accelMagnitude`. A group name stands for all values of the group.

## Settings from optiCLOUD

You can set three settings of the app in optiCLOUD through shared attributes of the device:

| Shared attribute | Type | Setting |
|---|---|---|
| `sendRate` | number | Send rate in seconds, 1 to 3600 |
| `sensors` | text | Sensor selection, for example `motion,location` |
| `dashboard` | text | Default dashboard on the [Favorites](favorites.md) tab, the ID of the dashboard |

- When the shared attribute exists, the app takes over its value and shows the setting as managed. It can then not be changed on the phone.
- When you delete the shared attribute, the app keeps the last value, and the setting can be changed on the phone again.
- A value the app cannot use is ignored and shown on the [Diagnosis](diagnosis.md) tab. This applies, for example, to a send rate outside the range or an unknown sensor name.
- If the phone is not connected at the moment, the app fetches the values at the next connect.

This lets you, for example, set the same selection for all phones of a project without setting up each one.

The app writes the shared attribute `sensorAppInstallation` itself. It binds the device to one phone. Do not change or delete it by hand.

## Commands

While the phone is connected, you can send it commands (RPC) from optiCLOUD, for example from a dashboard. The app answers every command and shows it on the [Diagnosis](diagnosis.md) tab.

| Command | Parameters | Effect | Answer |
|---|---|---|---|
| `ping` | none | none | `{ "pong": true }` |
| `getState` | none | none | for example `{ "transmitting": false, "sendRate": 5, "sensors": "motion,location" }` |
| `startTransmission` | none | Starts sending | `{ "transmitting": true }` |
| `stopTransmission` | none | Stops sending | `{ "transmitting": false }` |
| `setSendRate` | `{ "seconds": 5 }` | Changes the send rate | `{ "sendRate": 5 }` |
| `sendNow` | none | Measures all selected values at once and sends them, also while sending is off | `{ "sent": true }` |

If the app cannot carry out a command, it changes nothing and answers with an error, for example `{ "error": "unknown method" }`:

| Error | Cause |
|---|---|
| `unknown method` | The app does not know this command. |
| `invalid params` | A parameter is missing, has the wrong type, or is outside the range. |
| `managed setting` | The setting is managed through a shared attribute. |

A command reaches the phone only while it is connected. To let the phone receive commands without sending, switch on **Connected** under **Settings → Connection**.

## More details

The messages are described exactly in the specification: [`docs/spec/messages.md`](https://github.com/optimeas/opticloud-sensor-app/blob/main/docs/spec/messages.md).

---

This documentation is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Attribution: optiMEAS GmbH and optiMEAS Switzerland GmbH.
