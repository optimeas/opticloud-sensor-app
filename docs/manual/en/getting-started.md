---
title: Getting started
description: Sign in, choose a device, and send sensor values to optiCLOUD for the first time.
sidebar_label: Getting started
sidebar_position: 2
image: "/img/om_social_card.png"
keywords:
  - sign-in
  - tenant
  - project
  - device
  - access token
last_update:
  date: 2026-10-25
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Getting started

After the first start the app shows "No Device". Before it can send, you sign in to optiCLOUD and choose the device this phone sends to. This takes about a minute.

## Signing in

1. Tap **Sign In**.
2. Under **optiCLOUD** is the address of the optiCLOUD web application, preset to `https://dashboard.opticloud.io`. Change it only if you use another optiCLOUD server.
3. Enter the e-mail address and password of your personal optiCLOUD account and tap **Sign In**.
4. If you have access to several tenants, pick one. With only one tenant the app skips this step.
5. If the tenant requires a code by e-mail, enter it and tap **Confirm**. **Send New Code** requests a new one.
6. Pick the project.

The app does not store your password. It needs it only to sign in.

## Choosing a device

The app sends to a device in optiCLOUD, like any other hardware. The list shows only devices of the type "optiCLOUD Sensor App" in the chosen project.

- **Existing device:** tap the device.
- **New device:** tap **New Device**, enter a name, and tap **Create**. The name must be unique in the tenant, for example "iPhone Anna".

The app then binds the device to this phone and reads its access token. With the access token it later signs on to optiCLOUD as the device.

A device always sends from one phone only. If the chosen device is already bound to another phone, the app asks whether you want to take it over. If you take it over, the other phone stops sending to this device.

For these steps you need the permission in optiCLOUD to read and create devices and to write their attributes. If a permission is missing, the app says which one.

## Sending for the first time

1. Go to the **Live** tab.
2. Tap **Start Sending**. The app connects to optiCLOUD and starts sending.
3. The first time, iOS asks for the permissions the selected sensors need, for example for location. For background operation, first allow location "While Using the App"; the app then asks once for "Always" (see [Background and location](background.md)).

From now on the **Live** tab shows the measured values, and they arrive in optiCLOUD as telemetry of the device. Out of the box the app sends the values of the groups Device and Location every 2 seconds, and only when a value has changed. How to change this is in [Sending](sending.md) and [Sensors](sensors.md).

**Stop Sending** stops sending.

## The three tabs

| Tab | Content |
|---|---|
| **Live** | Start and stop sending, the current values |
| **Diagnosis** | Log, offline queue, sending test values (see [Diagnosis](diagnosis.md)) |
| **Settings** | Device, connection, transmission, sensors, data volume, account, about the app |

## Signing out

Under **Settings → Account** you sign out. Signing out does not stop sending: the phone goes on sending with the access token of the device until you stop sending. You only have to sign in again when you want to choose another device.

## Choosing another device

Under **Settings → Device** tap **Choose Another Device**. If values that have not been delivered yet are in the offline queue, the app says how many. They belong to the previous device and are discarded when you choose another one.

---

This documentation is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Attribution: optiMEAS GmbH and optiMEAS Switzerland GmbH.
