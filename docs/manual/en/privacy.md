---
title: Privacy
description: Which data the optiCLOUD Sensor app collects, where it goes, and what stays on the phone.
sidebar_label: Privacy
sidebar_position: 9
image: "/img/om_social_card.png"
keywords:
  - privacy
  - location
  - microphone
  - access token
  - keychain
last_update:
  date: 2026-10-26
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Privacy

The app measures things that can reveal a lot about you: where you are, how you move, how loud it is around you. That is why we say here exactly what it does with them. You can check it in the [source code](https://github.com/optimeas/opticloud-sensor-app).

## The essentials

- The app sends only to the optiCLOUD server you enter when signing in, and there only to the device you chose.
- It sends only while you have switched sending on, and only the sensors you selected.
- It contains no advertising and no analytics or tracking services, and talks to no other service.
- It records no audio. From the microphone it uses only the loudness.
- It does not store your password.

## What goes to optiCLOUD

| Data | When |
|---|---|
| The values of the selected sensors, with time stamps | While sending is switched on, and once on the command `sendNow` |
| App version, operating system, model of the phone, available and selected sensors, send rate, whether it is sending | After every connect and on changes |
| Answers to commands | When optiCLOUD sends a command |
| Values you send by hand on the Diagnosis tab | When you send them |
| E-mail address and password | Only when signing in, to sign you in |

In optiCLOUD this data belongs to the device in your tenant. Who can see it there is governed by the permissions in your tenant. Keep this in mind, especially for location: everyone who may see the device in optiCLOUD also sees where the phone was.

The connection is encrypted (TLS).

## What stays on the phone

- **In the iOS keychain:** the access token of the device, the session of your sign-in, and an identifier of the installation with which the app binds the device to this phone.
- **In the data of the app:** the settings, the offline queue with values not yet sent, the counters for the data volume, and the log on the Diagnosis tab. The log leaves the phone only when you export it yourself.

## Permissions

| Permission | What for |
|---|---|
| Location | The group Location, and with "Always" sending in the background (see [Background and location](background.md)) |
| Motion & Fitness | The group Activity (steps and kind of activity) and air pressure |
| Microphone | The group Sound: only the loudness |

iOS asks for a permission only when you have selected a sensor that needs it and start sending. You can withdraw every permission at any time in the iOS settings. The app then goes on sending the other values.

## Responsibility

For the data in optiCLOUD, the agreements between you or your company and the operator of the optiCLOUD server apply. For questions about the app you reach us through the [optiMEAS website](https://optimeas.com) or on [GitHub](https://github.com/optimeas/opticloud-sensor-app/issues).

---

This documentation is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Attribution: optiMEAS GmbH and optiMEAS Switzerland GmbH.
