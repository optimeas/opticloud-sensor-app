---
title: Sending
description: Send rate, send mode, connection, and offline queue of the optiCLOUD Sensor app.
sidebar_label: Sending
sidebar_position: 3
image: "/img/om_social_card.png"
keywords:
  - send rate
  - telemetry
  - MQTT
  - offline queue
  - connection
last_update:
  date: 2026-10-25
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Sending

The settings for sending are under **Settings → Transmission**. Sending is started and stopped on the **Live** tab.

## Send rate

The send rate sets how often the app measures and sends: once every 1 to 3600 seconds, every 2 seconds out of the box. Each tick gives one sample with a common time stamp.

Fast values such as acceleration and rotation rate are measured continuously at 50 Hz between two ticks. At every tick the app sends the mean, minimum, and maximum of these measurements. Shocks and vibration between two ticks are not lost, even with a long send rate.

## Send mode

| Mode | What the app sends |
|---|---|
| **On Change** (default) | At every tick only the values that have changed since they were last sent. All values once a minute. |
| **Every Tick** | All selected values at every tick. |

"Changed" means the value differs after rounding to the resolution of the sensor (see [Sensors](sensors.md)). A battery level of 0.8312 and 0.8349 is the same value when rounded to 0.01 and is not sent again. If nothing has changed at a tick, the app sends nothing.

The full sample once a minute gives optiCLOUD a regular reference point. "On Change" thus saves data volume without long gaps in optiCLOUD.

Values that only arise with an event, such as a change of activity, are sent at once in both modes.

## Connection

The app talks to optiCLOUD over MQTT, encrypted with TLS, and signs on with the access token of the device.

**Start Sending** also connects the app. Under **Settings → Connection** you can also keep the connection with **Connected** without sending. While the connection exists, optiCLOUD can send commands to the phone (see [The device in optiCLOUD](device-in-opticloud.md)).

The status shows how the connection is doing:

| Status | Meaning |
|---|---|
| **Disconnected** | No connection and no attempt. |
| **Connecting** | The app is opening the connection. |
| **Connected** | The app is connected to optiCLOUD. |
| **Waiting** | The connection was lost or could not be made, for example without a network. The app tries again on its own. |
| **Refused** | optiCLOUD refused the access token, or the device is bound to another phone. The app does not try again. |

When **Waiting**, the app first waits 1 second and doubles the pause with every failed attempt, up to 60 seconds. When iOS reports that the network is back, it tries at once.

When **Refused**, the only remedy is to choose the device again: sign in and choose the device again under **Settings → Device**. If another phone has taken over the device, this is how you get it back.

## Offline queue

Every sample first goes into a queue on the phone, also while the app is connected. From there the app delivers the samples, oldest first, and deletes them only when optiCLOUD has confirmed their receipt.

- Without a network the app goes on collecting. As soon as the connection is back, it delivers, with the original time stamps. This leaves no gap in optiCLOUD.
- The queue survives a restart of the app and of the phone.
- It holds up to 50 MB. When it is full, the app discards the oldest samples and counts them.
- If the connection breaks before optiCLOUD has confirmed a message, the app sends it again. optiCLOUD may then store single values twice, with the same time stamp.

How many samples are waiting and how many were discarded is shown on the [Diagnosis](diagnosis.md) tab.

## Managed by optiCLOUD

The send rate and the sensor selection can also be set from optiCLOUD, through shared attributes of the device (see [The device in optiCLOUD](device-in-opticloud.md)). When a setting is managed this way, the app shows it as "managed", and you cannot change it on the phone.

---

This documentation is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Attribution: optiMEAS GmbH and optiMEAS Switzerland GmbH.
