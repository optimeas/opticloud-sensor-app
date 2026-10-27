---
title: Background and location
description: How the optiCLOUD Sensor app goes on sending with the screen locked, and why it needs location for that.
sidebar_label: Background and location
sidebar_position: 5
image: "/img/om_social_card.png"
keywords:
  - background
  - location
  - location access
  - iOS
  - battery
last_update:
  date: 2026-10-28
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Background and location

iOS ends apps in the background after a short time. An app may only go on running in the background if it has a recognized reason. optiCLOUD Sensor uses location for this: as long as the app measures and sends the location, it may go on running, and with it all other selected sensors.

Location is not a pretext here but a measured value like any other. The app tells you openly what it needs it for, and iOS shows you at any time when it uses it.

## What you have to set

1. Select the group **Location** under **Settings → Transmission → Sensors** (selected out of the box).
2. Start sending. iOS asks for location; allow it "While Using the App".
3. Shortly afterwards iOS asks once whether the app may use location "Always". Allow it.

You see the current state under **Settings → Transmission → Location Access** while location is selected. If you have declined access, it shows **Open Settings**. Later you change it in the iOS Settings app under **optiCLOUD Sensor → Location**; choose **Always** there.

| Location access | What happens |
|---|---|
| **Always** | The app sends also with the screen locked and while you use another app. |
| **While Using the App** | The app sends while it is in the foreground. |
| **Never** | The app sends no location, and only while it is in the foreground. |

## What you see on the phone

While the app uses location, iOS shows an arrow in the status bar next to the time. This is intended: you always see that the app is measuring. When you stop sending, the arrow disappears.

## On the Lock Screen and in Control Center

While the app sends, it shows a **Live Activity** on the Lock Screen and in the Dynamic Island: the cloud of the app with the state, the device, how long it has been sending, and how many values are still waiting. The cloud is green while the app sends, orange while it waits for a connection, and red when optiCLOUD refused the device. **Stop** ends sending without opening the app.

The control **Send to optiCLOUD** starts and stops sending from Control Center, the Lock Screen, or the Action button. Add it in Control Center with **+** → **Add a Control**. To start sending, it opens the app briefly, because iOS starts the Live Activity only from the open app.

iOS ends a Live Activity after eight hours. Sending goes on; the next time you open the app, it shows a new one.

## Ending sending in the background

Stop sending on the **Live** tab with **Stop Sending**, with **Stop** in the Live Activity, or with the control **Send to optiCLOUD**.

Swiping the app away in the app switcher is **not** enough. Sending is a setting that survives a restart of the app: when the app starts again, it goes on sending. This is on purpose, because a measuring point should not fail just because the app was ended in between.

## What is missing in the background

- **Sound level:** iOS restricts the microphone in the background. The app measures it only while it is open.
- **Live view:** the values on the **Live** tab are updated only when you open the app again. They still arrive in optiCLOUD continuously.

## Battery

Measuring the location in the background costs power. How much depends on the phone, the reception, and the send rate. For long measurements a charger helps. You can follow the battery level yourself in optiCLOUD with the group **Device**.

---

This documentation is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Attribution: optiMEAS GmbH and optiMEAS Switzerland GmbH.
