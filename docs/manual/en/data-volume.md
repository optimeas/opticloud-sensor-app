---
title: Data volume
description: How the optiCLOUD Sensor app counts its own data volume and how to reduce it.
sidebar_label: Data volume
sidebar_position: 7
image: "/img/om_social_card.png"
keywords:
  - data volume
  - mobile network
  - Wi-Fi
  - send rate
last_update:
  date: 2026-10-25
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Data volume

If you use a phone as a measuring point on the move, you want to know what it costs in mobile data. The app therefore counts its own data volume.

## Where you see it

Under **Settings → Transmission → Data Volume Today** you see today's volume. Tap it, and the app shows sent (↑) and received (↓) data for today, this week (from Monday), and this month, each separately for the mobile network and Wi-Fi.

With the group **Device** the app also sends the totals for today and the month to optiCLOUD (see [Sensors](sensors.md)). This lets you follow the volume of several phones in one dashboard.

## How the app counts

The app counts every message it exchanges with optiCLOUD with its size. For encryption and network protocols it adds a fixed allowance per message. The result is an estimate: your mobile operator counts differently and can arrive at a somewhat different value. Other apps are not counted.

The counters apply per day in the local time of the phone. Which network counts is decided by iOS at the moment of the message.

How exactly the app counts is in the specification: [`docs/spec/connection.md`](https://github.com/optimeas/opticloud-sensor-app/blob/main/docs/spec/connection.md#data-volume).

## How to save data volume

- **Send mode "On Change"** (default): the app sends only values that have changed.
- **Longer send rate:** sending every 10 seconds instead of every 2 seconds gives far fewer messages.
- **Fewer sensors:** the group Motion sends mean, minimum, and maximum for several axes at every tick and changes almost always. Select only the values you need, for example only the acceleration magnitude.

Even without sending, an open connection uses a little volume, because the app checks it regularly.

---

This documentation is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Attribution: optiMEAS GmbH and optiMEAS Switzerland GmbH.
