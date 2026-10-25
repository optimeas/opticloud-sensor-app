---
title: Senden
description: Senderate, Sendemodus, Verbindung und Offline-Warteschlange der App optiCLOUD Sensor.
sidebar_label: Senden
sidebar_position: 3
image: "/img/om_social_card.png"
keywords:
  - Senderate
  - Telemetrie
  - MQTT
  - Offline-Warteschlange
  - Verbindung
last_update:
  date: 2026-10-25
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Senden

Die Einstellungen zum Senden findest du unter **Einstellungen → Senden**. Gestartet und gestoppt wird das Senden im Tab **Live**.

## Senderate

Die Senderate legt fest, wie oft die App misst und sendet: einmal alle 1 bis 3600 Sekunden, ab Werk alle 2 Sekunden. Jeder Takt ergibt eine Probe mit einem gemeinsamen Zeitstempel.

Schnelle Werte wie Beschleunigung und Drehrate misst die App zwischen zwei Takten laufend mit 50 Hz. Zu jedem Takt sendet sie Mittelwert, Minimum und Maximum dieser Messungen. So gehen Stöße und Vibrationen zwischen zwei Takten nicht verloren, auch bei einer langen Senderate.

## Sendemodus

| Modus | Was die App sendet |
|---|---|
| **Bei Änderung** (ab Werk) | Zu jedem Takt nur die Werte, die sich seit dem letzten Senden geändert haben. Einmal pro Minute alle Werte. |
| **Bei jedem Takt** | Zu jedem Takt alle gewählten Werte. |

„Geändert“ heißt: Der Wert unterscheidet sich nach dem Runden auf die Auflösung des Sensors (siehe [Sensoren](sensors.md)). Ein Akkustand von 0,8312 und 0,8349 ist auf 0,01 gerundet derselbe Wert und wird nicht erneut gesendet. Ändert sich zu einem Takt gar nichts, sendet die App nichts.

Die volle Probe einmal pro Minute gibt optiCLOUD einen regelmäßigen Bezugspunkt. „Bei Änderung“ spart so Datenvolumen, ohne dass in optiCLOUD lange Lücken entstehen.

Werte, die nur bei einem Ereignis entstehen, wie ein Wechsel der Aktivität, sendet die App in beiden Modi sofort.

## Verbindung

Die App spricht mit optiCLOUD über MQTT, verschlüsselt mit TLS, und meldet sich mit dem Access Token des Geräts an.

**Senden starten** verbindet die App auch. Unter **Einstellungen → Verbindung** kannst du die Verbindung zusätzlich mit **Verbunden** halten, ohne zu senden. Solange die Verbindung besteht, kann optiCLOUD Befehle an das Telefon senden (siehe [Das Gerät in optiCLOUD](device-in-opticloud.md)).

Der Status zeigt, wie es um die Verbindung steht:

| Status | Bedeutung |
|---|---|
| **Getrennt** | Keine Verbindung und kein Versuch. |
| **Verbinde** | Die App baut die Verbindung auf. |
| **Verbunden** | Die App ist mit optiCLOUD verbunden. |
| **Wartend** | Die Verbindung ist abgebrochen oder kam nicht zustande, zum Beispiel ohne Netz. Die App versucht es von selbst wieder. |
| **Abgelehnt** | optiCLOUD hat das Access Token abgelehnt, oder das Gerät ist an ein anderes Telefon gebunden. Die App versucht es nicht wieder. |

Bei **Wartend** wartet die App zuerst 1 Sekunde und verdoppelt die Pause mit jedem Fehlversuch bis auf 60 Sekunden. Meldet iOS, dass das Netz wieder da ist, versucht sie es sofort.

Bei **Abgelehnt** hilft nur, das Gerät erneut zu wählen: Melde dich an und wähle unter **Einstellungen → Gerät** das Gerät noch einmal. Hat ein anderes Telefon das Gerät übernommen, kannst du es so zurückholen.

## Offline-Warteschlange

Jede Probe geht zuerst in eine Warteschlange auf dem Telefon, auch wenn die App verbunden ist. Von dort liefert die App die Proben aus, die älteste zuerst, und löscht sie erst, wenn optiCLOUD den Empfang bestätigt hat.

- Ohne Netz sammelt die App weiter. Sobald die Verbindung wieder steht, liefert sie nach, mit den ursprünglichen Zeitstempeln. In optiCLOUD entsteht so keine Lücke.
- Die Warteschlange übersteht einen Neustart der App und des Telefons.
- Sie fasst bis zu 50 MB. Ist sie voll, verwirft die App die ältesten Proben und zählt sie.
- Bricht die Verbindung ab, bevor optiCLOUD eine Nachricht bestätigt hat, sendet die App sie erneut. optiCLOUD kann einzelne Werte dann doppelt speichern, mit demselben Zeitstempel.

Wie viele Proben warten und wie viele verworfen wurden, zeigt der Tab [Diagnose](diagnosis.md).

## Von optiCLOUD verwaltet

Senderate und Sensorauswahl lassen sich auch von optiCLOUD aus festlegen, über Shared Attributes des Geräts (siehe [Das Gerät in optiCLOUD](device-in-opticloud.md)). Ist eine Einstellung so verwaltet, zeigt die App sie mit „verwaltet“ an, und du kannst sie auf dem Telefon nicht ändern.

---

Diese Dokumentation steht unter [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.de). Namensnennung: optiMEAS GmbH und optiMEAS Switzerland GmbH.
