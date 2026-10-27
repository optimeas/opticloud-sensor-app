---
title: Diagnosis
description: Log, offline queue, and test values on the Diagnosis tab of the optiCLOUD Sensor app, and how to export the log.
sidebar_label: Diagnosis
sidebar_position: 9
image: "/img/om_social_card.png"
keywords:
  - diagnosis
  - log
  - support
  - offline queue
last_update:
  date: 2026-10-26
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Diagnosis

The **Diagnosis** tab shows what happens between the phone and optiCLOUD. It helps you check a connection, and it helps us help you with a problem.

## Send a value

Here you send a single value by hand, for example to test a dashboard or an alarm rule.

1. Enter a **Key** in lower camel case, for example `testValue`.
2. Choose the **Type**: Number, Text, or Yes/No.
3. Enter the **Value**.
4. Tap **Send as Telemetry** or **Send as Client Attribute**.

Telemetry goes through the offline queue like every measured value and arrives even if the connection is missing at the moment. A client attribute needs an existing connection.

## Offline queue

| Row | Meaning |
|---|---|
| **Samples** | How many samples are waiting for delivery |
| **Size** | How much space they take, at most 50 MB |
| **Oldest** | The time stamp of the oldest waiting sample |
| **Discarded** | How many samples the app discarded because the queue was full or optiCLOUD repeatedly did not accept a message |
| **Discarded Range** | The period the discarded samples come from |

**Reset Discarded Count** sets the count back to zero. How the queue works is in [Sending](sending.md).

## Log

The log shows, newest first:

- commands from optiCLOUD with their parameters and the answer of the app,
- changes of shared attributes, also of keys the app does not use; instead of the identifier of the installation in `sensorAppInstallation` it says only whether the binding belongs to this phone,
- values the app could not use, for example an invalid send rate,
- changes of the connection with their reason, for example "No network",
- the start and end of the location updates and problems with them,
- every start of the app, with a note when iOS started it in the background,
- when the app went to the background and back to the foreground, and **Paused** when iOS halted the app, with the length of the pause,
- values you sent by hand.

The log is kept in the data of the app on the phone and holds the last 1000 entries, also across a new start of the app. Entries of earlier days show the date. **Clear** empties it.

## Exporting the log

Tap the share symbol at the top right (a square with an arrow pointing up). VoiceOver calls it **Export Log**. The app creates a text that you can pass on by mail, by message, or as a file. It contains:

- the version of the app, the model of the phone, and the iOS version,
- device, project, tenant, and server,
- the state of the connection and of sending, the send rate and send mode,
- the selected sensors,
- the state of the offline queue,
- all entries of the log.

The text contains neither your password nor the access token of the device. You can read it before you pass it on: it is only text.

---

This documentation is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Attribution: optiMEAS GmbH and optiMEAS Switzerland GmbH.
