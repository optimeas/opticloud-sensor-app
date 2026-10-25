---
title: Sensoren
description: Welche Werte die App optiCLOUD Sensor misst, in welchen Einheiten und unter welchen Schlüsseln sie in optiCLOUD ankommen.
sidebar_label: Sensoren
sidebar_position: 4
image: "/img/om_social_card.png"
keywords:
  - Sensoren
  - Telemetrie
  - Beschleunigung
  - Standort
  - Schallpegel
last_update:
  date: 2026-10-25
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Sensoren

Die App bietet jeden Sensor an, den dein Telefon hat. Die Sensoren sind in Gruppen geordnet. Unter **Einstellungen → Senden → Sensoren** schaltest du ganze Gruppen ein und aus; tippst du auf eine Gruppe, kannst du darin einzelne Werte abwählen. Ab Werk sind die Gruppen Gerät und Standort gewählt.

Braucht ein Sensor eine Erlaubnis, fragt iOS danach, sobald das Senden startet. Lehnst du ab, fehlen die Werte dieses Sensors; die übrigen werden weiter gesendet.

In optiCLOUD kommen die Werte als Telemetrie des Geräts an, unter den Schlüsseln in den Tabellen unten. Ein Schlüssel hat auf iOS und Android dieselbe Einheit und dieselbe Bedeutung. Die App rundet jeden Wert auf die angegebene Auflösung. Ist ein Wert gerade nicht verfügbar, lässt die App ihn weg, statt einen Platzhalter zu senden.

## Bewegung

| Wert | Schlüssel | Einheit | Auflösung |
|---|---|---|---|
| Beschleunigung | `accelX`, `accelY`, `accelZ` | m/s² | 0,01 |
| Betrag der Beschleunigung | `accelMagnitude` | m/s² | 0,01 |
| Drehrate | `gyroX`, `gyroY`, `gyroZ` | rad/s | 0,001 |
| Magnetfeld | `magX`, `magY`, `magZ` | µT | 0,1 |
| Ausrichtung | `roll`, `pitch`, `yaw` | Grad | 0,1 |

Die Achsen beziehen sich auf das Telefon, aufrecht im Hochformat gehalten, Bildschirm zu dir: x zeigt nach rechts, y nach oben, z aus dem Bildschirm heraus. Ein Telefon, das flach auf dem Tisch liegt, misst auf z etwa +9,81 m/s², die Erdbeschleunigung. Der Betrag der Beschleunigung hängt nicht davon ab, wie das Telefon gehalten wird, und liegt in Ruhe bei etwa 9,81.

Beschleunigung und Drehrate misst die App mit 50 Hz und sendet zu jedem Takt den Mittelwert unter dem Schlüssel selbst, dazu Minimum und Maximum mit der Endung `Min` und `Max`, zum Beispiel `accelXMin` und `accelXMax`.

Zur Ausrichtung: `pitch` ist positiv, wenn die Oberkante angehoben ist (90 im Hochformat aufrecht), `roll` ist positiv, wenn die rechte Kante gesenkt ist, und `yaw` ist die Richtung der Oberkante im Uhrzeigersinn von magnetisch Nord. Solange iOS den Kompass nicht kalibriert hat, fehlen Magnetfeld und `yaw`.

## Umgebung

| Wert | Schlüssel | Einheit | Auflösung |
|---|---|---|---|
| Luftdruck | `pressure` | hPa | 0,1 |

Der Luftdruck braucht die Erlaubnis für „Bewegung & Fitness“.

Umgebungslicht (`light`) gibt es nur auf Android; iOS bietet dafür keine Schnittstelle.

## Standort

| Wert | Schlüssel | Einheit | Auflösung |
|---|---|---|---|
| Position | `latitude`, `longitude` | Grad (WGS 84) | 0,00001 |
| Höhe | `altitude` | m über Meer | 0,1 |
| Geschwindigkeit | `speed` | km/h | 0,1 |
| Kurs | `course` | Grad, im Uhrzeigersinn von Nord | 1 |
| Standortgenauigkeit | `locationAccuracy` | m | 1 |

Der Standort braucht deine Erlaubnis. Mit „Immer“ sendet die App auch im Hintergrund weiter (siehe [Hintergrund und Standort](background.md)).

## Aktivität

| Wert | Schlüssel | Einheit | Auflösung |
|---|---|---|---|
| Schritte heute | `steps` | Anzahl | 1 |
| Art der Aktivität | `activityType` | Text | – |

`steps` zählt ab Mitternacht Ortszeit. `activityType` ist einer der Texte `stationary`, `walking`, `running`, `cycling`, `automotive` oder `unknown` und wird gesendet, sobald iOS eine neue Aktivität erkennt. Ein stehendes Auto gilt weiter als `automotive`. Die Gruppe braucht die Erlaubnis für „Bewegung & Fitness“.

## Gerät

| Wert | Schlüssel | Einheit | Auflösung |
|---|---|---|---|
| Akkustand | `batteryLevel` | 0 bis 1 | 0,01 |
| Lädt | `charging` | ja/nein | – |
| Netzwerk | `network` | Text | – |
| Temperaturzustand | `thermalState` | Text | – |
| Stromsparmodus | `powerSaving` | ja/nein | – |
| Datenvolumen | `dataMobileToday`, `dataWifiToday`, `dataMobileMonth`, `dataWifiMonth` | Byte | 1000 |

`network` ist `wifi`, `cellular`, `other` oder `none`. `thermalState` ist `nominal`, `fair`, `serious` oder `critical`. Das Datenvolumen ist das der App selbst, heute und im laufenden Monat (siehe [Datenvolumen](data-volume.md)).

Die Signalstärke des Mobilfunks (`cellularSignal`) gibt es nur auf Android; iOS bietet dafür keine öffentliche Schnittstelle.

## Schall

| Wert | Schlüssel | Einheit | Auflösung |
|---|---|---|---|
| Schallpegel | `soundLevel` | dB | 1 |

Die App misst nur die Lautstärke. Sie nimmt keinen Ton auf und sendet keinen.

Ein Telefonmikrofon ist nicht kalibriert. Der Schallpegel ist deshalb ein Schätzwert: der Pegel aller Messungen seit dem letzten Takt relativ zum Vollausschlag, plus 100 dB. Ein ruhiger Raum ergibt etwa 30 bis 50, ein Gespräch etwa 60 bis 70. Verschiedene Telefone können um einige Dezibel voneinander abweichen.

Den Schallpegel misst die App nur, solange sie geöffnet ist. iOS schränkt das Mikrofon im Hintergrund ein; im Hintergrund fehlt der Wert deshalb.

## Gesundheit

Werte wie Herzfrequenz oder Sauerstoffsättigung von einer Uhr sind geplant und kommen in einer späteren Version.

## Mehr Details

Die vollständige Beschreibung mit allen Formeln und Regeln steht in der Spezifikation: [`docs/spec/sensors.md`](https://github.com/optimeas/opticloud-sensor-app/blob/main/docs/spec/sensors.md).

---

Diese Dokumentation steht unter [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.de). Namensnennung: optiMEAS GmbH und optiMEAS Switzerland GmbH.
