---
title: Datenvolumen
description: Wie die App optiCLOUD Sensor ihr eigenes Datenvolumen zählt und wie du es senkst.
sidebar_label: Datenvolumen
sidebar_position: 7
image: "/img/om_social_card.png"
keywords:
  - Datenvolumen
  - Mobilfunk
  - WLAN
  - Senderate
last_update:
  date: 2026-10-25
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Datenvolumen

Wer ein Telefon als Messpunkt unterwegs einsetzt, will wissen, was das an Mobilfunkdaten kostet. Die App zählt deshalb ihr eigenes Datenvolumen.

## Wo du es siehst

Unter **Einstellungen → Senden → Datenvolumen heute** siehst du das Volumen von heute. Tippst du darauf, zeigt die App gesendete (↑) und empfangene (↓) Daten für heute, diese Woche (ab Montag) und diesen Monat, jeweils getrennt nach Mobilfunk und WLAN.

Mit der Gruppe **Gerät** sendet die App die Summen für heute und den Monat auch an optiCLOUD (siehe [Sensoren](sensors.md)). So kannst du das Volumen mehrerer Telefone in einem Dashboard verfolgen.

## Wie die App zählt

Die App zählt jede Nachricht, die sie mit optiCLOUD austauscht, mit ihrer Größe. Für Verschlüsselung und Netzwerkprotokolle rechnet sie pro Nachricht einen festen Zuschlag dazu. Das Ergebnis ist eine Schätzung: Dein Mobilfunkanbieter rechnet anders und kann auf einen etwas anderen Wert kommen. Andere Apps zählen nicht mit.

Die Zähler gelten pro Tag in der Ortszeit des Telefons. Welches Netz gilt, entscheidet iOS im Moment der Nachricht.

Wie genau gezählt wird, steht in der Spezifikation: [`docs/spec/connection.md`](https://github.com/optimeas/opticloud-sensor-app/blob/main/docs/spec/connection.md#data-volume).

## Wie du Datenvolumen sparst

- **Sendemodus „Bei Änderung“** (ab Werk): Die App sendet nur Werte, die sich geändert haben.
- **Längere Senderate:** Alle 10 Sekunden statt alle 2 Sekunden senden ergibt deutlich weniger Nachrichten.
- **Weniger Sensoren:** Die Gruppe Bewegung sendet zu jedem Takt Mittelwert, Minimum und Maximum für mehrere Achsen und ändert sich fast immer. Wähle nur die Werte, die du brauchst, zum Beispiel nur den Betrag der Beschleunigung.

Auch ohne Senden verbraucht eine bestehende Verbindung ein wenig Volumen, weil die App sie regelmäßig prüft.

---

Diese Dokumentation steht unter [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.de). Namensnennung: optiMEAS GmbH und optiMEAS Switzerland GmbH.
