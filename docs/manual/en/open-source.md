---
title: Why open source
description: Why optiMEAS publishes the optiCLOUD Sensor app and its interface.
sidebar_label: Why open source
sidebar_position: 1
image: "/img/om_social_card.png"
keywords:
  - open source
  - MIT
  - transparency
  - optiCLOUD
  - interface
last_update:
  date: 2026-10-25
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Why open source

optiCLOUD Sensor is open source. The complete source code of both apps, the specification, and this documentation are public on GitHub: [github.com/optimeas/opticloud-sensor-app](https://github.com/optimeas/opticloud-sensor-app). The code is under the MIT license, the documentation under CC BY 4.0.

The reasons go beyond this one app.

## You can see what the app sends

An app that measures location, motion, and noise deserves distrust as long as nobody can check what it does with them. With optiCLOUD Sensor you can check. Every value the app sends is described in the specification, and the code that measures and sends it can be read by anyone. The app sends only to the optiCLOUD device you chose yourself, and to no other service. What that means in detail is in [Privacy](privacy.md).

Honesty is part of it: where the app estimates, it says so. The sound level is an estimate, not a calibrated measurement, and the data volume is a calculation, not the bill of your mobile operator.

## An example of a connection to optiCLOUD

The app is also a complete, working example of how a device talks to optiCLOUD:

- signing in through the REST interface and creating or picking a device,
- sending telemetry and client attributes over MQTT,
- receiving shared attributes and letting optiCLOUD manage settings,
- accepting and answering commands (RPC),
- buffering measurements without a network and delivering them in the right order.

If you want to connect a device, a gateway, or software of your own to optiCLOUD, you find a whole here, not an excerpt, one that runs in everyday use – in Swift for iOS, and soon in Kotlin for Android as well.

## An open specification

The apps follow a common specification in the folder [`docs/spec`](https://github.com/optimeas/opticloud-sensor-app/tree/main/docs/spec). It describes sign-in, connection, messages, sensors, and the offline queue in our own words. Test vectors define how values are rounded, selected, aggregated, and packed. Both apps must pass every vector. This keeps iOS and Android the same, and anyone who writes a third implementation can check it against the same vectors.

## Get to know us

optiMEAS stands for competence, meeting as equals, openness, honesty, and knowledge. Rather than just claim it, we show our work: how we record requirements, give reasons for decisions, test, and document. You can form your own picture before you work with us.

We share knowledge because sharing makes it grow. What we learned about sensors, background operation, and MQTT on smartphones while building the app is in the specification and in the code – the stumbling blocks included.

## Take part

Bugs, questions, and suggestions are welcome on GitHub, as an issue or a pull request. We treat contributions as equals, whether they come from a customer, a student, or another company. How the work in the repository is organized is in the [README](https://github.com/optimeas/opticloud-sensor-app#readme).

## Not our first project of this kind

optiCLOUD Sensor is not our first open project. The Open Streaming Format (OSF), our file format for measurement and process data, is also openly specified and published on GitHub: [github.com/optimeas/osf](https://github.com/optimeas/osf). Its documentation is under data formats in the [optiMEAS documentation](https://docs.optimeas.com). Both projects follow the same idea: what we make public, anyone can check, use, and improve.

---

This documentation is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Attribution: optiMEAS GmbH and optiMEAS Switzerland GmbH.
