---
title: Das Gerät in optiCLOUD
description: Telemetrie, Client-Attribute, Shared Attributes und Befehle eines Geräts der App optiCLOUD Sensor.
sidebar_label: Das Gerät in optiCLOUD
sidebar_position: 6
image: "/img/om_social_card.png"
keywords:
  - Gerät
  - Telemetrie
  - Client-Attribut
  - Shared Attributes
  - RPC
last_update:
  date: 2026-10-25
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Das Gerät in optiCLOUD

Für optiCLOUD ist dein Telefon ein Gerät wie jedes andere. Du findest es im gewählten Projekt unter seinem Namen, mit dem Gerätetyp „optiCLOUD Sensor App“. Seine Werte nutzt du in Dashboards, Alarmregeln und Berichten wie die jedes anderen Geräts.

## Telemetrie

Die Messwerte kommen als Telemetrie an. Jeder Wert hat den Zeitstempel, zu dem er gemessen wurde, nicht den, zu dem er gesendet wurde. Werte aus der Offline-Warteschlange erscheinen deshalb an der richtigen Stelle der Zeitreihe. Welche Schlüssel es gibt, steht unter [Sensoren](sensors.md).

## Client-Attribute

Nach jedem Verbinden und bei jeder Änderung meldet die App, was das Telefon ist und was es gerade tut:

| Schlüssel | Inhalt |
|---|---|
| `appVersion` | Version der App |
| `os` | `iOS` oder `Android` |
| `osVersion` | Version des Betriebssystems |
| `model` | Modell des Telefons, zum Beispiel `iPhone 16 Pro Max` |
| `sensorsAvailable` | Die Werte, die dieses Telefon bietet |
| `sensors` | Die Werte, die gerade gewählt sind |
| `sendRate` | Die Senderate in Sekunden |
| `transmitting` | Ob das Telefon gerade sendet |

`sensorsAvailable` und `sensors` sind Listen aus Gruppen und Werten, durch Kommas getrennt, zum Beispiel `device,location,accelMagnitude`. Ein Gruppenname steht für alle Werte der Gruppe.

## Einstellungen aus optiCLOUD

Zwei Einstellungen der App kannst du in optiCLOUD über Shared Attributes des Geräts festlegen:

| Shared Attribute | Typ | Einstellung |
|---|---|---|
| `sendRate` | Zahl | Senderate in Sekunden, 1 bis 3600 |
| `sensors` | Text | Sensorauswahl, zum Beispiel `motion,location` |

- Gibt es das Shared Attribute, übernimmt die App seinen Wert und zeigt die Einstellung als verwaltet an. Auf dem Telefon lässt sie sich dann nicht ändern.
- Löschst du das Shared Attribute, behält die App den letzten Wert, und die Einstellung lässt sich auf dem Telefon wieder ändern.
- Einen Wert, den die App nicht verwenden kann, ignoriert sie und zeigt das im Tab [Diagnose](diagnosis.md). Das gilt zum Beispiel für eine Senderate außerhalb des Bereichs oder einen unbekannten Sensornamen.
- Ist das Telefon gerade nicht verbunden, holt die App die Werte beim nächsten Verbinden ab.

So kannst du zum Beispiel für alle Telefone eines Projekts dieselbe Auswahl festlegen, ohne jedes einzeln einzustellen.

Das Shared Attribute `sensorAppInstallation` schreibt die App selbst. Es bindet das Gerät an ein Telefon. Ändere oder lösche es nicht von Hand.

## Befehle

Solange das Telefon verbunden ist, kannst du ihm aus optiCLOUD Befehle (RPC) schicken, zum Beispiel aus einem Dashboard. Die App beantwortet jeden Befehl und zeigt ihn im Tab [Diagnose](diagnosis.md).

| Befehl | Parameter | Wirkung | Antwort |
|---|---|---|---|
| `ping` | keine | keine | `{ "pong": true }` |
| `getState` | keine | keine | zum Beispiel `{ "transmitting": false, "sendRate": 5, "sensors": "motion,location" }` |
| `startTransmission` | keine | Startet das Senden | `{ "transmitting": true }` |
| `stopTransmission` | keine | Stoppt das Senden | `{ "transmitting": false }` |
| `setSendRate` | `{ "seconds": 5 }` | Ändert die Senderate | `{ "sendRate": 5 }` |
| `sendNow` | keine | Misst sofort alle gewählten Werte und sendet sie, auch wenn das Senden aus ist | `{ "sent": true }` |

Kann die App einen Befehl nicht ausführen, ändert sie nichts und antwortet mit einem Fehler, zum Beispiel `{ "error": "unknown method" }`:

| Fehler | Ursache |
|---|---|
| `unknown method` | Die App kennt diesen Befehl nicht. |
| `invalid params` | Ein Parameter fehlt, hat den falschen Typ oder liegt außerhalb des Bereichs. |
| `managed setting` | Die Einstellung wird über ein Shared Attribute verwaltet. |

Ein Befehl erreicht das Telefon nur, solange es verbunden ist. Damit das Telefon auch ohne Senden Befehle empfängt, schalte unter **Einstellungen → Verbindung** die Option **Verbunden** ein.

## Mehr Details

Die Nachrichten sind in der Spezifikation genau beschrieben: [`docs/spec/messages.md`](https://github.com/optimeas/opticloud-sensor-app/blob/main/docs/spec/messages.md).

---

Diese Dokumentation steht unter [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.de). Namensnennung: optiMEAS GmbH und optiMEAS Switzerland GmbH.
